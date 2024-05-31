module Install.ClauseInCaseTest2 exposing (all)

import Install.ClauseInCase
import Run
import Test exposing (Test, describe, test)


all : Test
all =
    describe "Install.ClauseInCase"
        [ Run.testFix test1

        --, makeTestExpectNoErrors "Test 2" src1 rule1
        -- , makeTestExpectNoErrors "Test 2" src2 rule2
        ]



-- TEST 1


test1 =
    { description = "Test 1: should report an error and fix it"
    , src = src1
    , rule = rule1
    , under = under1
    , fixed = fixed1
    , message = "Add handler for ResetCounter"
    }


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


rule2 =
    Install.ClauseInCase.init "Frontend" "update" "Reset" "( { model | counter = 0 }, sendToBackend CounterReset )"
        |> Install.ClauseInCase.makeRule


src2 =
    """module Frontend exposing (Model, app)

update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
       update msg model =
           case msg of
               Increment ->
                   ( { model | counter = model.counter + 1 }, sendToBackend CounterIncremented )
       
               Decrement ->
                   ( { model | counter = model.counter - 1 }, sendToBackend CounterDecremented )
       
               FNoop ->
                   ( model, Cmd.none )
                   
"""
