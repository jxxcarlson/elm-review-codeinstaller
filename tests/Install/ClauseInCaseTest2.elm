module Install.ClauseInCaseTest2 exposing (all)

import Expect exposing (Expectation)
import Install.ClauseInCase
import Review.Rule exposing (Rule)
import Review.Test
import Test exposing (Test, describe, test)


all : Test
all =
    describe "Install.ClauseInCase"
        [ makeTest "Test 1: should report an error and fix it" src1 rule1 under1 "Add handler for ResetCounter"
        ]


makeTest : String -> String -> Rule -> String -> String -> Test
makeTest description src rule under message =
    test description <|
        \() ->
            src
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error { message = message, details = [ "" ], under = under }
                        |> Review.Test.whenFixed fixed1
                    ]



-- TEST 1


rule1 =
    Install.ClauseInCase.init "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.makeRule


src1 =
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


fixed1 =
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


         ResetCounter -> ( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )


"""


under1 =
    """case msg of
         CounterIncremented ->
            let
                newCounter =
                    model.counter + 1
            in
            ( { model | counter = newCounter }, broadcast (CounterNewValue newCounter clientId) )"""



-- TEST 2
