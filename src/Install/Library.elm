module Install.Library exposing (..)

import Elm.Parser
import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Case, CaseBlock, Expression(..), FunctionImplementation, Lambda)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Pattern exposing (Pattern(..))
import Elm.Syntax.Range as Range exposing (Range)
import Review.ModuleNameLookupTable as ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule
import Set exposing (Set)


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

        _ ->
            []


lastRange : Expression -> Range
lastRange expr =
    case expr of
        RecordExpr fields ->
            List.map (\(Node rg _) -> rg) fields
                |> List.reverse
                |> List.head
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
visitExpression namespace ignored ((Node _ expression) as expressionNode) context =
    case expression of
        FunctionOrValue moduleName name ->
            case ModuleNameLookupTable.fullModuleNameFor context.lookupTable expressionNode of
                Nothing ->
                    context

                Just fullModuleName ->
                    if
                        List.isEmpty moduleName && Set.member name ignored
                        --|| Set.member fullModuleNameJoined coreModules
                    then
                        context

                    else
                        context

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


getDeclarationName : Node Declaration -> String
getDeclarationName declaration =
    let
        getName declaration_ =
            declaration_ |> .name >> Node.value
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

{-| Converts an expression to a string. Not fully implemented yet, so check if it cover your case before using. -}
expressionToString : Node Expression -> String
expressionToString (Node _ expression) =
    case expression of
        FunctionOrValue moduleName name ->
            case moduleName of
                [] ->
                    name

                _ ->
                    String.join "." moduleName ++ "." ++ name

        IfBlock c t f ->
            "if " ++ expressionToString c ++ " then " ++ expressionToString t ++ " else " ++ expressionToString f

        -- OperatorApplication op l r ->
        --     expressionToString l ++ " " ++ op ++ " " ++ expressionToString r
        Application children ->
            String.join " " (List.map expressionToString children)

        TupledExpression children ->
            "(" ++ String.join ", " (List.map expressionToString children) ++ ")"

        ListExpr children ->
            "[" ++ String.join ", " (List.map expressionToString children) ++ "]"

        Negation child ->
            "-" ++ expressionToString child

        ParenthesizedExpression child ->
            "(" ++ expressionToString child ++ ")"

        RecordAccess child field ->
            expressionToString child ++ "." ++ Node.value field

        -- CaseExpression caseBlock ->
        --     "case " ++ expressionToString caseBlock.expression ++ " of " ++ String.join " " (List.map caseToString caseBlock.cases)
        -- LambdaExpression lambda ->
        --     "\\" ++ String.join " " (List.map patternToString lambda.args) ++ " -> " ++ expressionToString lambda.expression
        -- RecordExpr recordSetters ->
        --     "{ " ++ String.join ", " (List.map recordSetterToString recordSetters) ++ " }"
        -- RecordUpdateExpression record recordSetters ->
        --     "{ " ++ expressionToString record ++ " | " ++ String.join ", " (List.map recordSetterToString recordSetters) ++ " }"
        _ ->
            ""
