module Install.ClauseInCaseTest2 exposing (all)

import Install.ClauseInCase exposing (init, makeRule)
import Review.Test
import Test exposing (Test, describe, test)


all : Test
all =
    let
        rule =
            Install.ClauseInCase.init "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
                |> Install.ClauseInCase.makeRule
    in
    describe "Install.ClauseInCase"
        [ test "should report an error and fix it" <|
            \() ->
                """module Backend exposing (..)

updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
         CounterIncremented ->
            let
                newCounter =
                    model.counter + 1
            in
            ( { model | counter = newCounter }, broadcast (CounterNewValue newCounter clientId) )


"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error { message = "Add handler for ResetCounter", details = [ "" ], under = """case msg of
         CounterIncremented ->
            let
                newCounter =
                    model.counter + 1
            in
            ( { model | counter = newCounter }, broadcast (CounterNewValue newCounter clientId) )""" }
                            |> Review.Test.whenFixed """module Backend exposing (..)

updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
         CounterIncremented ->
            let
                newCounter =
                    model.counter + 1
            in
            ( { model | counter = newCounter }, broadcast (CounterNewValue newCounter clientId) )


         ResetCounter -> ( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )


"""
                        ]
        ]
