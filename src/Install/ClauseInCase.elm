module Install.ClauseInCase exposing
    ( Config, config
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

@docs Config, config

By default, the clause will be inserted as the last clause. You can change the insertion location using the following functions:

@docs withInsertAfter, withInsertAtBeginning
@docs withCustomErrorMessage

-}

import Install.Internal.ClauseInCase as Internal


{-| Configuration for rule: add a clause to a case expression in a specified function in a specified module.
-}
type alias Config =
    Internal.Config


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
config hostModuleName functionName clause functionCall =
    Internal.Config
        { hostModuleName = String.split "." hostModuleName
        , functionName = functionName
        , clause = clause
        , functionCall = functionCall
        , insertAt = Internal.AtEnd
        , customErrorMessage = { message = "Add handler for " ++ clause, details = [ "" ] }
        }


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
withInsertAfter clauseToInsertAfter (Internal.Config config_) =
    Internal.Config
        { config_
            | insertAt = Internal.After clauseToInsertAfter
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
withInsertAtBeginning (Internal.Config config_) =
    Internal.Config
        { config_
            | insertAt = Internal.AtBeginning
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
withCustomErrorMessage errorMessage details (Internal.Config config_) =
    Internal.Config
        { config_
            | customErrorMessage = { message = errorMessage, details = details }
        }



-- HELPERS
