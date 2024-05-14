module Install.Library exposing (..)

{-|

@docs rule

-}

import Elm.Syntax.Expression exposing (Case, CaseBlock, Expression(..), Function, FunctionImplementation, Lambda, LetBlock, LetDeclaration(..))
import Elm.Syntax.Node as Node exposing (Node(..), range)
import Elm.Syntax.Pattern exposing (Pattern(..))
import Elm.Syntax.Range as Range exposing (Range)
import Review.ModuleNameLookupTable as ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (Error, Rule)
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
                    let
                        fullModuleNameJoined : String
                        fullModuleNameJoined =
                            String.join "." fullModuleName
                    in
                    if
                        List.isEmpty moduleName && Set.member name ignored
                        --|| Set.member fullModuleNameJoined coreModules
                    then
                        context

                    else
                        let
                            fullName : String
                            fullName =
                                fullModuleNameJoined
                                    ++ "."
                                    ++ name
                        in
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
