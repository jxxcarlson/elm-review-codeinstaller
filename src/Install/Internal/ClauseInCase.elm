module Install.Internal.ClauseInCase exposing
    ( Config(..)
    , InsertAt(..)
    , declarationVisitor
    )

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Case, Expression(..), FunctionImplementation)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Pattern exposing (Pattern(..))
import Elm.Syntax.Range exposing (Range)
import Install.Library
import List.Extra
import Maybe.Extra
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error)


type Config
    = Config
        { hostModuleName : ModuleName
        , functionName : String
        , clause : String
        , functionCall : String
        , insertAt : InsertAt
        , customErrorMessage : ErrorMessage
        }


type InsertAt
    = After String
    | AtBeginning
    | AtEnd


type alias ErrorMessage =
    { message : String
    , details : List String
    }


declarationVisitor : Config -> Node Declaration -> List (Rule.Error {})
declarationVisitor ((Config { functionName }) as config) (Node _ declaration) =
    case declaration of
        FunctionDeclaration function ->
            if Node.value (Node.value function.declaration).name == functionName then
                let
                    functionDeclaration : FunctionImplementation
                    functionDeclaration =
                        Node.value function.declaration
                in
                visitFunction config functionDeclaration.expression

            else
                []

        _ ->
            []


visitFunction : Config -> Node Expression -> List (Rule.Error {})
visitFunction (Config config) expressionNode =
    let
        couldNotFindCaseError node =
            Rule.error
                { message = "Could not find the case expression"
                , details = [ "Try to extract the case to a top-level function and call the rule on the new function" ]
                }
                (Node.range node)
    in
    case findNestedCaseNode expressionNode of
        Just caseNode ->
            let
                caseExpression =
                    Node.value caseNode

                ( allCases, patternMatchNode ) =
                    case caseExpression of
                        CaseExpression { cases, expression } ->
                            ( cases, expression )

                        -- impossible case
                        _ ->
                            ( [], Node.empty caseExpression )

                getPatterns : List Case -> List Pattern
                getPatterns cases_ =
                    cases_
                        |> List.map (\( pattern, _ ) -> Node.value pattern)

                findClause : String -> List Case -> Bool
                findClause clause_ cases_ =
                    List.any
                        (\pattern -> Install.Library.patternToString (Node.empty pattern) == clause_)
                        (getPatterns cases_)
            in
            if not (findClause config.clause allCases) then
                let
                    isClauseStringPattern =
                        List.any isStringPattern (getPatterns allCases)

                    rangeToInsert : Maybe ( Range, Int )
                    rangeToInsert =
                        rangeToInsertClause config.insertAt isClauseStringPattern allCases patternMatchNode |> Just
                in
                [ errorWithFix config.customErrorMessage isClauseStringPattern config.clause config.functionCall caseNode rangeToInsert ]

            else
                []

        Nothing ->
            [ couldNotFindCaseError expressionNode ]


rangeToInsertClause : InsertAt -> Bool -> List Case -> Node Expression -> ( Range, Int )
rangeToInsertClause insertAt isClauseStringPattern cases expression =
    let
        lastClauseExpression =
            cases
                |> List.Extra.last
                |> Maybe.map Tuple.second
                |> Maybe.withDefault expression

        lastClauseStartingColumn =
            cases
                |> List.Extra.last
                |> Maybe.map Tuple.first
                |> Maybe.map (Node.range >> .start >> .column)
                |> Maybe.withDefault 0
                |> (\x -> x - 1)
    in
    case insertAt of
        After previousClause ->
            let
                normalizedPreviousClause =
                    if isClauseStringPattern then
                        escapeString previousClause

                    else
                        previousClause

                previousClausePattern =
                    cases
                        |> List.Extra.find
                            (\( pattern, _ ) ->
                                Install.Library.patternToString pattern == normalizedPreviousClause
                            )
            in
            case previousClausePattern of
                Just pattern ->
                    pattern
                        |> Tuple.second
                        |> Node.range
                        |> (\range -> ( range, lastClauseStartingColumn ))

                Nothing ->
                    ( Node.range lastClauseExpression, 0 )

        AtBeginning ->
            let
                -- If there are other clauses, the first clause will take the start of other clauses as reference.
                otherClausesOffset =
                    cases
                        |> List.map (\( pattern, _ ) -> Node.range pattern |> .start |> .column)
                        |> List.minimum
                        |> Maybe.map (\x -> x - 1)

                -- If there are no other clauses, the first clause will take the case expression as reference. The -2 is to account for the `case` keyword and the space after it
                firstClauseOffset =
                    (Node.range expression).start.column - 2

                clauseOffset =
                    otherClausesOffset
                        |> Maybe.withDefault firstClauseOffset
            in
            ( Node.range expression, clauseOffset )

        AtEnd ->
            let
                range =
                    Node.range lastClauseExpression
            in
            ( range, lastClauseStartingColumn )


errorWithFix : ErrorMessage -> Bool -> String -> String -> Node a -> Maybe ( Range, Int ) -> Error {}
errorWithFix errorMessage isClauseStringPattern clause functionCall node errorRange =
    Rule.errorWithFix
        errorMessage
        (Node.range node)
        (case errorRange of
            Just ( range, horizontalOffset ) ->
                let
                    insertionPoint =
                        { row = range.end.row + 1, column = 0 }

                    prefix =
                        String.repeat horizontalOffset " "
                in
                [ addMissingCase insertionPoint isClauseStringPattern prefix clause functionCall ]

            Nothing ->
                []
        )


addMissingCase : { row : Int, column : Int } -> Bool -> String -> String -> String -> Fix
addMissingCase { row, column } isClauseStringPattern prefix clause functionCall =
    let
        clauseToAdd =
            if isClauseStringPattern then
                escapeString clause

            else
                clause

        insertion =
            "\n" ++ prefix ++ clauseToAdd ++ " -> " ++ functionCall ++ "\n"
    in
    Fix.insertAt { row = row, column = column } insertion



-- HELPERS


findNestedCaseNode : Node Expression -> Maybe (Node Expression)
findNestedCaseNode node =
    case Node.value node of
        CaseExpression _ ->
            Just node

        Application nodes ->
            List.Extra.findMap findNestedCaseNode nodes

        OperatorApplication _ _ first second ->
            Maybe.Extra.orLazy (findNestedCaseNode first) (\_ -> findNestedCaseNode second)

        IfBlock _ thenNode elseNode ->
            Maybe.Extra.orLazy (findNestedCaseNode thenNode) (\_ -> findNestedCaseNode elseNode)

        Negation nestedNode ->
            findNestedCaseNode nestedNode

        TupledExpression nodes ->
            List.Extra.findMap findNestedCaseNode nodes

        ParenthesizedExpression nestedNode ->
            findNestedCaseNode nestedNode

        LetExpression { expression } ->
            findNestedCaseNode expression

        LambdaExpression { expression } ->
            findNestedCaseNode expression

        ListExpr nodes ->
            List.Extra.findMap findNestedCaseNode nodes

        _ ->
            Nothing


isStringPattern : Pattern -> Bool
isStringPattern pattern =
    case pattern of
        StringPattern _ ->
            True

        _ ->
            False


escapeString : String -> String
escapeString str =
    if isStringScaped str then
        str

    else
        "\"" ++ str ++ "\""


isStringScaped : String -> Bool
isStringScaped str =
    String.startsWith "\\" str
