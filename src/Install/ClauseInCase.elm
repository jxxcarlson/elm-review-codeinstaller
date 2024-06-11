module Install.ClauseInCase exposing (init, makeRule, withInsertAfter, withInsertAtBeginning, withCustomErrorMessage, Config, CustomError)

{-| Add a clause to a case expression in a specified function
in a specified module. For example, if you put the code below in your
`ReviewConfig.elm` file, running `elm-review --fix` will add the clause
`ResetCounter` to the `updateFromFrontend` function in the `Backend` module.

    -- code for ReviewConfig.elm:
    Install.ClauseInCase.init "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
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

    You also can add the clause after another clause of choice with the `withInsertAfter` function:
        Install.ClauseInCase.init "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
            |> Install.ClauseInCase.withInsertAfter "CounterIncremented"
            |> Install.ClauseInCase.makeRule

    In this case we will have
        updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
        updateFromFrontend sessionId clientId msg model =
            case msg of
                CounterIncremented ->
                ...
                ResetCounter ->
                    ( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )

                CounterDecremented ->
                ...
    You can also customize the error message with the `withCustomErrorMessage` function:
        Install.ClauseInCase.init "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
            |> Install.ClauseInCase.withCustomErrorMessage "Add handler for ResetCounter" []
            |> Install.ClauseInCase.makeRule

@docs init, makeRule, withInsertAfter, withInsertAtBeginning, withCustomErrorMessage, Config, CustomError

-}

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Case, Expression(..), Function, FunctionImplementation)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Pattern exposing (Pattern(..))
import Elm.Syntax.Range exposing (Range)
import Install.Library
import List.Extra
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error, Rule)
import Set exposing (Set)
import String.Extra


{-| Configuration for makeRule: add a clause to a case expression in a specified function in a specified module.
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

    Install.ClauseInCase.init "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.makeRule
    If you need additional configuration, check the `withInsertAfter` and `withCustomErrorMessage` functions.

-}
init : String -> String -> String -> String -> Config
init moduleName functionName clause functionCall =
    Config
        { moduleName = moduleName
        , functionName = functionName
        , clause = clause
        , functionCall = functionCall
        , insertAt = AtEnd
        , customErrorMessage = CustomError { message = "Add handler for " ++ clause, details = [ "" ] }
        }


{-| Create a makeRule that adds a clause to a case expression in a specified function. You can use it like this:

    Install.ClauseInCase.init "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.makeRule

-}
makeRule : Config -> Rule
makeRule (Config config) =
    let
        visitor : Node Declaration -> Context -> ( List (Error {}), Context )
        visitor declaration context =
            declarationVisitor declaration config.moduleName config.functionName config.clause config.functionCall config.insertAt context config.customErrorMessage
    in
    Rule.newModuleRuleSchemaUsingContextCreator "Install.ClauseInCase" contextCreator
        |> Rule.withDeclarationEnterVisitor visitor
        |> Rule.providesFixesForModuleRule
        |> Rule.fromModuleRuleSchema


type alias Context =
    { moduleName : ModuleName
    }


type alias Ignored =
    Set String


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

                namespace : String
                namespace =
                    String.join "." context.moduleName ++ "." ++ name

                isInCorrectModule =
                    Install.Library.isInCorrectModule moduleName context
            in
            if name == functionName && isInCorrectModule then
                visitFunction namespace clause functionCall Set.empty function insertAt customError context

            else
                ( [], context )

        _ ->
            ( [], context )


visitFunction : String -> String -> String -> Ignored -> Function -> InsertAt -> CustomError -> Context -> ( List (Rule.Error {}), Context )
visitFunction namespace clause functionCall ignored function insertAt customError context =
    let
        declaration : FunctionImplementation
        declaration =
            Node.value function.declaration
    in
    case declaration.expression |> Node.value of
        CaseExpression { expression, cases } ->
            let
                getPatterns : List Case -> List Pattern
                getPatterns cases_ =
                    cases_
                        |> List.map (\( pattern, _ ) -> Node.value pattern)

                findClause : String -> List Case -> Bool
                findClause clause_ cases_ =
                    List.any
                        (\pattern -> patternToString pattern == clause_)
                        (getPatterns cases_)

                isClauseStringPattern =
                    List.any isStringPattern (getPatterns cases)
            in
            if not (findClause clause cases) then
                let
                    rangeToInsert : Maybe ( Range, Int, Int )
                    rangeToInsert =
                        rangeToInsertClause insertAt isClauseStringPattern cases expression |> Just
                in
                ( [ errorWithFix customError isClauseStringPattern clause functionCall declaration.expression rangeToInsert ], context )

            else
                ( [], context )

        _ ->
            ( [], context )


rangeToInsertClause : InsertAt -> Bool -> List Case -> Node Expression -> ( Range, Int, Int )
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
                                nodePatternToString pattern == normalizedPreviousClause
                            )
            in
            case previousClausePattern of
                Just pattern ->
                    pattern
                        |> Tuple.second
                        |> Node.range
                        |> (\range -> ( range, 2, lastClauseStartingColumn ))

                Nothing ->
                    ( Node.range lastClauseExpression, 2, 0 )

        AtBeginning ->
            let
                -- The -2 is to account for the `case` keyword and the space after it
                firstClauseOffset =
                    (Node.range expression).start.column - 2
            in
            ( Node.range expression, 1, firstClauseOffset )

        AtEnd ->
            let
                range =
                    Node.range lastClauseExpression
            in
            ( range, 2, lastClauseStartingColumn )


errorWithFix : CustomError -> Bool -> String -> String -> Node a -> Maybe ( Range, Int, Int ) -> Error {}
errorWithFix (CustomError customError) isClauseStringPattern clause functionCall node errorRange =
    Rule.errorWithFix
        customError
        (Node.range node)
        (case errorRange of
            Just ( range, verticalOffset, horizontalOffset ) ->
                let
                    insertionPoint =
                        { row = range.end.row + verticalOffset, column = 0 }

                    prefix =
                        "\n" ++ String.repeat horizontalOffset " "
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
            prefix ++ clauseToAdd ++ " -> " ++ functionCall ++ "\n\n"
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

    Install.ClauseInCase.init "Philosopher" "stringToPhilosopher" "Aspasia" "Just Aspasia"
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
withInsertAfter clauseToInsertAfter (Config config) =
    Config
        { config
            | insertAt = After clauseToInsertAfter
        }


{-| Add a clause at the beginning of the case expression.
-}
withInsertAtBeginning : Config -> Config
withInsertAtBeginning (Config config) =
    Config
        { config
            | insertAt = AtBeginning
        }


{-| Customize the error message that will be displayed when running `elm-review --fix` or `elm-review --fix-all`
-}
withCustomErrorMessage : String -> List String -> Config -> Config
withCustomErrorMessage errorMessage details (Config config) =
    Config
        { config
            | customErrorMessage = CustomError { message = errorMessage, details = details }
        }



-- HELPERS


patternToString : Pattern -> String
patternToString pattern =
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
                "(" ++ String.join ", " (List.map nodePatternToString patterns) ++ ")"

            RecordPattern fields ->
                "{ " ++ String.join ", " (List.map Node.value fields) ++ " }"

            UnConsPattern head tail ->
                nodePatternToString head ++ " :: " ++ nodePatternToString tail

            ListPattern patterns ->
                "[" ++ String.join ", " (List.map nodePatternToString patterns) ++ "]"

            VarPattern var ->
                var

            NamedPattern qualifiedNameRef pattern_ ->
                qualifiedNameRef.name ++ " " ++ String.join " " (List.map nodePatternToString pattern_)

            AsPattern pattern_ (Node _ var) ->
                nodePatternToString pattern_ ++ " as " ++ var

            ParenthesizedPattern pattern_ ->
                "(" ++ nodePatternToString pattern_ ++ ")"


nodePatternToString : Node Pattern -> String
nodePatternToString node =
    node
        |> Node.value
        |> patternToString


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
