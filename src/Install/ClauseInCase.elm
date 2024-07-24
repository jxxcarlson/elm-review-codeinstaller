module Install.ClauseInCase exposing
    ( Config, config, makeRule
    , withInsertAfter, withInsertAtBeginning
    , withCustomErrorMessage
    )

{-| Add a clause to a case expression in a specified function
in a specified module. For example, if you put the code below in your
`ReviewConfig.elm` file, running `elm-review --fix` will add the clause
`ResetCounter` to the `updateFromFrontend` function in the `Backend` module.

    -- code for ReviewConfig.elm:
    Install.ClauseInCase.config
        "Backend"
        "updateFromFrontend"
        "ResetCounter"
        "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.makeRule

Thus we will have

    updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
    updateFromFrontend sessionId clientId msg model =
        case msg of
            CounterIncremented ->
            ...
            CounterDecremented ->
            ...
            ResetCounter ->
                ( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )

            ...

@docs Config, config, makeRule

By default, the clause will be inserted as the last clause. You can change the insertion location using the following functions:

@docs withInsertAfter, withInsertAtBeginning
@docs withCustomErrorMessage

-}

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
import Review.Rule as Rule exposing (Error, Rule)


{-| Configuration for rule: add a clause to a case expression in a specified function in a specified module.
-}
type Config
    = Config
        { moduleName : String
        , functionName : String
        , clause : String
        , functionCall : String
        , insertAt : InsertAt
        , customErrorMessage : CustomError
        }


type InsertAt
    = After String
    | AtBeginning
    | AtEnd


{-| Custom error message to be displayed when running `elm-review --fix` or `elm-review --fix-all`
-}
type CustomError
    = CustomError { message : String, details : List String }


{-| Basic config to add a new clause to a case expression. If you just need to add a new clause at the end of the case, you can simply use it with the `makeRule` function like this:

    Install.ClauseInCase.config
        "Backend"
        "updateFromFrontend"
        "ResetCounter"
        "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.makeRule

If you need additional configuration, check the `withInsertAfter` and `withCustomErrorMessage` functions.

-}
config : String -> String -> String -> String -> Config
config moduleName functionName clause functionCall =
    Config
        { moduleName = moduleName
        , functionName = functionName
        , clause = clause
        , functionCall = functionCall
        , insertAt = AtEnd
        , customErrorMessage = CustomError { message = "Add handler for " ++ clause, details = [ "" ] }
        }


{-| Create a rule that adds a clause to a case expression in a specified function. You can use it like this:

    Install.ClauseInCase.config
        "Backend"
        "updateFromFrontend"
        "ResetCounter"
        "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.makeRule

-}
makeRule : Config -> Rule
makeRule (Config config_) =
    let
        visitor : Node Declaration -> Context -> ( List (Error {}), Context )
        visitor declaration context =
            declarationVisitor declaration config_.moduleName config_.functionName config_.clause config_.functionCall config_.insertAt context config_.customErrorMessage
    in
    Rule.newModuleRuleSchemaUsingContextCreator "Install.ClauseInCase" contextCreator
        |> Rule.withDeclarationEnterVisitor visitor
        |> Rule.providesFixesForModuleRule
        |> Rule.fromModuleRuleSchema


type alias Context =
    { moduleName : ModuleName
    }


contextCreator : Rule.ContextCreator () { moduleName : ModuleName }
contextCreator =
    Rule.initContextCreator
        (\moduleName () ->
            { moduleName = moduleName

            -- ...other fields
            }
        )
        |> Rule.withModuleName


declarationVisitor : Node Declaration -> String -> String -> String -> String -> InsertAt -> Context -> CustomError -> ( List (Rule.Error {}), Context )
declarationVisitor (Node _ declaration) moduleName functionName clause functionCall insertAt context customError =
    case declaration of
        FunctionDeclaration function ->
            let
                name : String
                name =
                    Node.value (Node.value function.declaration).name

                isInCorrectModule =
                    Install.Library.isInCorrectModule moduleName context
            in
            if name == functionName && isInCorrectModule then
                let
                    functionDeclaration : FunctionImplementation
                    functionDeclaration =
                        Node.value function.declaration
                in
                visitFunction clause functionCall functionDeclaration.expression insertAt customError context

            else
                ( [], context )

        _ ->
            ( [], context )


visitFunction : String -> String -> Node Expression -> InsertAt -> CustomError -> Context -> ( List (Rule.Error {}), Context )
visitFunction clause functionCall expressionNode insertAt customError context =
    let
        couldNotFindCaseError node =
            Rule.error { message = "Could not find the case expression", details = [ "Try to extract the case to a top-level function and call the rule on the new function" ] } (Node.range node)
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
            if not (findClause clause allCases) then
                let
                    isClauseStringPattern =
                        List.any isStringPattern (getPatterns allCases)

                    rangeToInsert : Maybe ( Range, Int )
                    rangeToInsert =
                        rangeToInsertClause insertAt isClauseStringPattern allCases patternMatchNode |> Just
                in
                ( [ errorWithFix customError isClauseStringPattern clause functionCall caseNode rangeToInsert ], context )

            else
                ( [], context )

        Nothing ->
            ( [ couldNotFindCaseError expressionNode ], context )


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
                        |> List.map (\( pattern, _ ) -> Node.range pattern |> .start >> .column)
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


errorWithFix : CustomError -> Bool -> String -> String -> Node a -> Maybe ( Range, Int ) -> Error {}
errorWithFix (CustomError customError) isClauseStringPattern clause functionCall node errorRange =
    Rule.errorWithFix
        customError
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



-- CONFIGURATION


{-| Add a clause after another clause of choice in a case expression. If the clause to insert after is not found, the new clause will be inserted at the end.


## Example

Given the following module:

    module Philosopher exposing (Philosopher(..), stringToPhilosopher)

    type Philosopher
        = Socrates
        | Plato
        | Aristotle

    stringToPhilosopher : String -> Maybe Philosopher
    stringToPhilosopher str =
        case str of
            "Socrates" ->
                Just Socrates

            "Plato" ->
                Just Plato

            "Aristotle" ->
                Just Aristotle

            _ ->
                Nothing

To add the clause `Aspasia` after the clause `Aristotle`, you can use the following configuration:

    Install.ClauseInCase.config
        "Philosopher"
        "stringToPhilosopher"
        "Aspasia"
        "Just Aspasia"
        |> Install.ClauseInCase.withInsertAfter "Aristotle"
        |> Install.ClauseInCase.makeRule

This will add the clause `Aspasia` after the clause `Aristotle` in the `stringToPhilosopher` function, resulting in:

    stringToPhilosopher : String -> Maybe Philosopher
    stringToPhilosopher str =
        case str of
            "Socrates" ->
                Just Socrates

            "Plato" ->
                Just Plato

            "Aristotle" ->
                Just Aristotle

            "Aspasia" ->
                Just Aspasia

            _ ->
                Nothing

-}
withInsertAfter : String -> Config -> Config
withInsertAfter clauseToInsertAfter (Config config_) =
    Config
        { config_
            | insertAt = After clauseToInsertAfter
        }


{-| Add a clause at the beginning of the case expression.

You also can add the clause after another clause of choice with the `withInsertAfter` function:

    Install.ClauseInCase.config
        "Backend"
        "updateFromFrontend"
        "ResetCounter"
        "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.withInsertAtBeginning
        |> Install.ClauseInCase.makeRule

In this case we will have

    updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
    updateFromFrontend sessionId clientId msg model =
        case msg of
            ResetCounter ->
                ( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )

            CounterIncremented ->
            ...

            CounterDecremented ->
            ...

-}
withInsertAtBeginning : Config -> Config
withInsertAtBeginning (Config config_) =
    Config
        { config_
            | insertAt = AtBeginning
        }


{-| Customize the error message that will be displayed when running `elm-review --fix` or `elm-review --fix-all`.

    Install.ClauseInCase.config
        "Backend"
        "updateFromFrontend"
        "ResetCounter"
        "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.withCustomErrorMessage "Add handler for ResetCounter" []
        |> Install.ClauseInCase.makeRule

-}
withCustomErrorMessage : String -> List String -> Config -> Config
withCustomErrorMessage errorMessage details (Config config_) =
    Config
        { config_
            | customErrorMessage = CustomError { message = errorMessage, details = details }
        }



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
