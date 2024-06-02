module Install.ClauseInCase exposing
    ( init, makeRule, withInsertAfter, withCustomErrorMessage, Config, CustomError
    , withInsertAtBeginning
    )

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

@docs init, makeRule, withInsertAfter, withCustomErrorMessage, Config, CustomError

-}

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Case, Expression(..), Function, FunctionImplementation)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Pattern exposing (Pattern(..))
import Elm.Syntax.Range exposing (Range)
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
            in
            if name == functionName && moduleName == String.join "." context.moduleName then
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
            in
            if not (findClause clause cases) then
                let
                    rangeToInsert : Maybe ( Range, Int, Int )
                    rangeToInsert =
                        rangeToInsertClause insertAt cases expression |> Just
                in
                ( [ errorWithFix customError clause functionCall declaration.expression rangeToInsert ], context )

            else
                ( [], context )

        _ ->
            ( [], context )


rangeToInsertClause : InsertAt -> List Case -> Node Expression -> ( Range, Int, Int )
rangeToInsertClause insertAt cases expression =
    let
        lastClauseExpression =
            cases
                |> List.Extra.last
                |> Maybe.map Tuple.second
                |> Maybe.withDefault expression

        firstClauseExpression =
            cases
                |> List.head
                |> Maybe.map Tuple.second
                |> Maybe.withDefault expression

        _ =
            Debug.log "LAST CLAUSE RANGE" (Node.range lastClauseExpression)

        _ =
            Debug.log "FIRST CLAUSE RANGE" (Node.range firstClauseExpression)
    in
    case insertAt of
        After previousClause ->
            let
                previousClausePattern =
                    cases
                        |> List.Extra.find
                            (\( pattern, _ ) ->
                                nodePatternToString pattern == previousClause
                            )
            in
            case previousClausePattern of
                Just pattern ->
                    pattern
                        |> Tuple.second
                        |> Node.range
                        |> Debug.log "NODE RANGE (1)"
                        |> (\range -> ( range, 2, range.start.column |> Debug.log "H OFFSET" ))

                Nothing ->
                    ( Node.range lastClauseExpression |> Debug.log "NODE RANGE (2)", 2, 0 )

        AtBeginning ->
            -- TODO: Review, is it correct?
            ( Node.range expression |> Debug.log "NODE RANGE (3)", 1, 0 )

        AtEnd ->
            let
                range =
                    Node.range lastClauseExpression |> Debug.log "NODE RANGE (4)"
            in
            ( range, 2, range.start.column |> Debug.log "H OFFSET" )


errorWithFix : CustomError -> String -> String -> Node a -> Maybe ( Range, Int, Int ) -> Error {}
errorWithFix (CustomError customError) clause functionCall node errorRange =
    let
        deltaH =
            Node.range node |> .start |> .row |> Debug.log "@@NODE RANGE, start, row"
    in
    Rule.errorWithFix
        customError
        (Node.range node |> Debug.log "RANGE")
        (case errorRange of
            Just ( range, verticalOffset, horizontalOffset ) ->
                let
                    horizontalOffset2 =
                        Debug.log "@@@ horizontalOffset2" horizontalOffset - deltaH + 1

                    insertionPoint =
                        { row = range.end.row + verticalOffset, column = 0 }

                    prefix =
                        "\n" ++ String.repeat horizontalOffset2 " "
                in
                [ addMissingCase insertionPoint prefix clause functionCall |> Debug.log "insertion" ]

            Nothing ->
                []
        )


addMissingCase : { row : Int, column : Int } -> String -> String -> String -> Fix
addMissingCase { row, column } prefix clause functionCall =
    let
        insertion =
            prefix ++ clause ++ " -> " ++ functionCall ++ "\n\n"
    in
    Fix.insertAt ({ row = row, column = column } |> Debug.log "INSERTING AT") insertion



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
