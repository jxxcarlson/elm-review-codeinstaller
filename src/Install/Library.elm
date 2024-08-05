module Install.Library exposing (..)

import Elm.Parser
import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Case, CaseBlock, Expression(..), Function, FunctionImplementation, Lambda, LetDeclaration(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Pattern exposing (Pattern(..))
import Elm.Syntax.Range as Range exposing (Range)
import List.Extra
import Review.ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule
import Set exposing (Set)
import Set.Extra as Set
import String.Extra


type alias Ignored =
    Set String


type alias Context =
    { lookupTable : ModuleNameLookupTable
    , moduleName : String
    }


fieldNames : Expression -> List String
fieldNames expr =
    case expr of
        RecordExpr fields ->
            List.map (\(Node _ ( name, _ )) -> Node.value name) fields

        Application children ->
            List.concatMap (Node.value >> fieldNames) children

        _ ->
            []


lastRange : Expression -> Range
lastRange expr =
    case expr of
        RecordExpr fields ->
            fields
                |> List.reverse
                |> List.head
                |> Maybe.map
                    (\setter ->
                        Node.value setter
                            |> Tuple.second
                            |> Node.range
                    )
                |> Maybe.withDefault Range.empty

        Application children ->
            List.Extra.findMap
                (\child ->
                    let
                        expression =
                            Node.value child
                    in
                    case expression of
                        RecordExpr _ ->
                            Just expression

                        _ ->
                            Nothing
                )
                children
                |> Maybe.map lastRange
                |> Maybe.withDefault Range.empty

        _ ->
            Range.empty


initContext : Rule.ContextCreator () Context
initContext =
    Rule.initContextCreator
        (\lookupTable () ->
            { lookupTable = lookupTable
            , moduleName = ""
            }
        )
        |> Rule.withModuleNameLookupTable


type alias ModuleContext =
    { moduleName : String
    , lookupTable : ModuleNameLookupTable
    }


extractNamesFromPatterns : List (Node Pattern) -> Set String -> Set String
extractNamesFromPatterns patterns set =
    List.foldl extractNamesFromPattern set patterns


extractNamesFromPattern : Node Pattern -> Set String -> Set String
extractNamesFromPattern (Node _ pattern) set =
    case pattern of
        VarPattern v ->
            Set.insert v set

        RecordPattern fields ->
            List.foldl (\(Node _ field) -> Set.insert field) set fields

        UnConsPattern head tail ->
            extractNamesFromPatterns [ head, tail ] set

        ListPattern children ->
            extractNamesFromPatterns children set

        TuplePattern children ->
            extractNamesFromPatterns children set

        NamedPattern _ children ->
            extractNamesFromPatterns children set

        AsPattern child (Node _ var) ->
            extractNamesFromPattern child (Set.insert var set)

        ParenthesizedPattern child ->
            extractNamesFromPattern child set

        _ ->
            set


visitExpression : String -> Ignored -> Node Expression -> ModuleContext -> ModuleContext
visitExpression namespace ignored (Node _ expression) context =
    case expression of
        IfBlock c t f ->
            visitExpressions namespace ignored [ c, t, f ] context

        OperatorApplication _ _ l r ->
            visitExpressions namespace ignored [ l, r ] context

        Application children ->
            visitExpressions namespace ignored children context

        TupledExpression children ->
            visitExpressions namespace ignored children context

        ListExpr children ->
            visitExpressions namespace ignored children context

        Negation child ->
            visitExpression namespace ignored child context

        ParenthesizedExpression child ->
            visitExpression namespace ignored child context

        RecordAccess child _ ->
            visitExpression namespace ignored child context

        CaseExpression caseBlock ->
            visitCaseBlock namespace ignored caseBlock context

        LambdaExpression lambda ->
            visitLambda namespace ignored lambda context

        RecordExpr recordSetters ->
            visitRecordSetters namespace ignored recordSetters context

        RecordUpdateExpression _ recordSetters ->
            visitRecordSetters namespace ignored recordSetters context

        _ ->
            context


visitExpressions : String -> Ignored -> List (Node Expression) -> ModuleContext -> ModuleContext
visitExpressions namespace ignored expressions context =
    List.foldl (visitExpression namespace ignored) context expressions


visitRecordSetters : String -> Ignored -> List (Node Elm.Syntax.Expression.RecordSetter) -> ModuleContext -> ModuleContext
visitRecordSetters namespace ignored recordSetters context =
    List.foldl
        (\(Node _ ( _, expression )) -> visitExpression namespace ignored expression)
        context
        recordSetters


visitLambda : String -> Ignored -> Lambda -> ModuleContext -> ModuleContext
visitLambda namespace ignored { args, expression } context =
    visitExpression namespace
        (extractNamesFromPatterns args ignored)
        expression
        context


visitCaseBlock : String -> Ignored -> CaseBlock -> ModuleContext -> ModuleContext
visitCaseBlock namespace ignored caseBlock context =
    List.foldl
        (visitCase namespace ignored)
        (visitExpression namespace ignored caseBlock.expression context)
        caseBlock.cases


visitCase : String -> Ignored -> Case -> ModuleContext -> ModuleContext
visitCase namespace ignored ( pattern, expression ) context =
    visitExpression namespace
        (extractNamesFromPattern pattern ignored)
        expression
        context


toNodeList : { a | moduleName : ModuleName } -> String -> List (Node Declaration)
toNodeList context str =
    let
        moduleName =
            context.moduleName
                |> String.join "."
    in
    "module "
        ++ moduleName
        ++ " exposing(..)\n\n"
        ++ str
        |> Elm.Parser.parseToFile
        |> Result.map .declarations
        |> Result.withDefault []


expressionFromNodeFunctionImplementation : Node FunctionImplementation -> Node Expression
expressionFromNodeFunctionImplementation (Node _ impl) =
    impl.expression


getExpressionFromString : { a | moduleName : ModuleName } -> String -> Maybe (Node Expression)
getExpressionFromString context str =
    str |> getFunctionImplementation context |> Maybe.map expressionFromNodeFunctionImplementation


maybeNodeExpressionFromNodeDeclaration : Node Declaration -> Maybe (Node Expression)
maybeNodeExpressionFromNodeDeclaration node =
    case node of
        Node _ (FunctionDeclaration f) ->
            Just (expressionFromNodeFunctionImplementation f.declaration)

        _ ->
            Nothing


maybeNodeExpressionFromString : { a | moduleName : ModuleName } -> String -> Maybe (Node Expression)
maybeNodeExpressionFromString context str =
    case toNodeList context str |> List.head of
        Just node ->
            maybeNodeExpressionFromNodeDeclaration node

        _ ->
            Nothing


getFunctionImplementation : { a | moduleName : ModuleName } -> String -> Maybe (Node FunctionImplementation)
getFunctionImplementation context str =
    case toNodeList context str |> List.head of
        Just (Node _ (FunctionDeclaration f)) ->
            Just f.declaration

        _ ->
            Nothing


isInCorrectModule : String -> { a | moduleName : ModuleName } -> Bool
isInCorrectModule moduleName context =
    context.moduleName
        |> String.join "."
        |> (==) moduleName


isInCorrectFunction : String -> Function -> Bool
isInCorrectFunction functionName function =
    functionName == Node.value (Node.value function.declaration).name


getDeclarationName : Node Declaration -> String
getDeclarationName declaration =
    let
        getName declaration_ =
            declaration_ |> .name |> Node.value
    in
    case Node.value declaration of
        FunctionDeclaration function ->
            getName (Node.value function.declaration)

        AliasDeclaration alias_ ->
            getName alias_

        CustomTypeDeclaration customType ->
            getName customType

        PortDeclaration port_ ->
            getName port_

        _ ->
            ""


expressionToString : Node Expression -> String
expressionToString (Node _ expr) =
    let
        recordSetterToString : Node Elm.Syntax.Expression.RecordSetter -> String
        recordSetterToString (Node _ ( name, expression )) =
            Node.value name ++ " = " ++ expressionToString expression
    in
    String.Extra.clean <|
        case expr of
            FunctionOrValue moduleName name ->
                case moduleName of
                    [] ->
                        name

                    _ ->
                        String.join "." moduleName ++ "." ++ name

            IfBlock c t f ->
                "if " ++ expressionToString c ++ " then " ++ expressionToString t ++ " else " ++ expressionToString f

            Application children ->
                String.join " " (List.map expressionToString children)

            TupledExpression children ->
                "(" ++ String.join ", " (List.map expressionToString children) ++ ")"

            ListExpr children ->
                "[" ++ String.join ", " (List.map expressionToString children) ++ "]"

            Negation child ->
                "not " ++ expressionToString child

            ParenthesizedExpression child ->
                "(" ++ expressionToString child ++ ")"

            RecordAccess child field ->
                expressionToString child ++ "." ++ Node.value field

            Literal str ->
                "\"" ++ str ++ "\""

            CharLiteral char ->
                "'" ++ String.fromChar char ++ "'"

            UnitExpr ->
                "()"

            OperatorApplication op _ l r ->
                expressionToString l ++ " " ++ op ++ " " ++ expressionToString r

            PrefixOperator op ->
                op

            Operator op ->
                op

            Integer int ->
                String.fromInt int

            Hex hex ->
                "0x" ++ String.fromInt hex

            Floatable float ->
                String.fromFloat float

            LetExpression { declarations, expression } ->
                let
                    letDeclarationsToString declaration =
                        case declaration of
                            LetFunction function ->
                                let
                                    ( name, args, expression_ ) =
                                        function.declaration
                                            |> Node.value
                                            |> (\dec -> ( Node.value dec.name, dec.arguments, dec.expression ))
                                in
                                name
                                    ++ " "
                                    ++ String.join " " (List.map patternToString args)
                                    ++ " = "
                                    ++ expressionToString expression_

                            LetDestructuring pattern exprs ->
                                patternToString pattern ++ " = " ++ expressionToString exprs
                in
                "let " ++ String.join " " (List.map (Node.value >> letDeclarationsToString) declarations) ++ " in " ++ expressionToString expression

            CaseExpression caseBlock ->
                let
                    caseToString ( pattern, expression ) =
                        patternToString pattern ++ " -> " ++ expressionToString expression
                in
                "case " ++ expressionToString caseBlock.expression ++ " of " ++ String.join " " (List.map caseToString caseBlock.cases)

            LambdaExpression lambda ->
                "\\" ++ String.join " " (List.map patternToString lambda.args) ++ " -> " ++ expressionToString lambda.expression

            RecordExpr recordSetters ->
                "{" ++ String.join ", " (List.map recordSetterToString recordSetters) ++ "}"

            RecordUpdateExpression record recordSetters ->
                "{" ++ Node.value record ++ " | " ++ String.join ", " (List.map recordSetterToString recordSetters) ++ "}"

            RecordAccessFunction field ->
                "." ++ field

            GLSLExpression str ->
                str


patternToString : Node Pattern -> String
patternToString (Node _ pattern) =
    String.Extra.clean <|
        case pattern of
            AllPattern ->
                "_"

            UnitPattern ->
                "()"

            CharPattern char ->
                "'" ++ String.fromChar char ++ "'"

            StringPattern str ->
                "\"" ++ str ++ "\""

            IntPattern int ->
                String.fromInt int

            HexPattern hex ->
                "0x" ++ String.fromInt hex

            FloatPattern float ->
                String.fromFloat float

            TuplePattern patterns ->
                "(" ++ String.join ", " (List.map patternToString patterns) ++ ")"

            RecordPattern fields ->
                "{ " ++ String.join ", " (List.map Node.value fields) ++ " }"

            UnConsPattern head tail ->
                patternToString head ++ " :: " ++ patternToString tail

            ListPattern patterns ->
                "[" ++ String.join ", " (List.map patternToString patterns) ++ "]"

            VarPattern var ->
                var

            NamedPattern qualifiedNameRef pattern_ ->
                qualifiedNameRef.name ++ " " ++ String.join " " (List.map patternToString pattern_)

            AsPattern pattern_ (Node _ var) ->
                patternToString pattern_ ++ " as " ++ var

            ParenthesizedPattern pattern_ ->
                "(" ++ patternToString pattern_ ++ ")"


declarationToString : Node Declaration -> String
declarationToString (Node _ declaration) =
    String.Extra.clean <|
        case declaration of
            FunctionDeclaration function ->
                let
                    ( name, args, expression ) =
                        function.declaration
                            |> Node.value
                            |> (\dec -> ( Node.value dec.name, dec.arguments, dec.expression ))
                in
                name
                    ++ " "
                    ++ String.join " " (List.map patternToString args)
                    ++ " = "
                    ++ expressionToString expression

            _ ->
                ""


isStringEqualToDeclaration : String -> Node Declaration -> Bool
isStringEqualToDeclaration str decl =
    let
        removeTypeAnnotation initialString =
            initialString
                |> String.lines
                |> (\lines ->
                        case lines of
                            [] ->
                                []

                            first :: rest ->
                                if String.contains ":" first && String.contains "->" first then
                                    rest

                                else
                                    lines
                   )
                |> String.concat
    in
    (declarationToString >> deepCleanString) decl == (removeTypeAnnotation >> deepCleanString) str


isStringEqualToExpression : String -> Node Expression -> Bool
isStringEqualToExpression str expr =
    (expressionToString >> deepCleanString) expr == deepCleanString str


areItemsInList : List String -> List (Node Expression) -> Bool
areItemsInList newItems oldItems =
    let
        stringifiedExprs : Set String
        stringifiedExprs =
            oldItems
                |> List.map (expressionToString >> deepCleanString)
                |> Set.fromList

        cleanedNewItems : List String
        cleanedNewItems =
            newItems
                |> List.map deepCleanString
    in
    Set.isSubsetOf stringifiedExprs (Set.fromList cleanedNewItems)


deepCleanString : String -> String
deepCleanString =
    String.Extra.clean >> String.replace " " ""
