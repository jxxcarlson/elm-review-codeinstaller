module Install.ClauseInCaseTest2 exposing (all)

import Install.ClauseInCase
import Run
import Test exposing (Test, describe, test)


all : Test
all =
    describe "Install.ClauseInCase"
        [ Run.testFix test1a
        , Run.testFix test1b
        , Run.testFix test1c
        , Run.testFix test2
        ]



-- TEST 1


test1a =
    { description = "Test 1a, simple makeRule: should report an error and fix it"
    , src = src1
    , rule = rule1a
    , under = under1
    , fixed = fixed1
    , message = "Add handler for ResetCounter"
    }


test1b =
    { description = "Test 1b, withInsertAfter CounterIncremented: should report an error and fix it"
    , src = src1
    , rule = rule1b
    , under = under1
    , fixed = fixed1
    , message = "Add handler for ResetCounter"
    }


test1c =
    { description = "Test 1c, withInsertAtBeginning: should report an error and fix it"
    , src = src1
    , rule = rule1c
    , under = under1
    , fixed = fixed1c
    , message = "Add handler for ResetCounter"
    }


rule1a =
    Install.ClauseInCase.init "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.makeRule


rule1b =
    Install.ClauseInCase.init "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.withInsertAfter "CounterIncremented"
        |> Install.ClauseInCase.makeRule


rule1c =
    Install.ClauseInCase.init "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.withInsertAtBeginning
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


fixed1c =
    """module Backend exposing (..)

updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of

        ResetCounter -> ( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )

        CounterIncremented ->
            let
                newCounter =
                    model.counter + 1
            in
            ( { model | counter = newCounter }, broadcast (CounterNewValue newCounter clientId) )


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


test2 =
    { description = "Test 2 (Reset, Frontend.update): should report an error and fix it"
    , src = src2
    , rule = rule2
    , under = under2
    , fixed = fixed2
    , message = "Add handler for Reset"
    }


rule2 =
    Install.ClauseInCase.init "Frontend" "update" "Reset" "( { model | counter = 0 }, sendToBackend CounterReset )"
        |> Install.ClauseInCase.withInsertAfter "Increment"
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


fixed2 =
    """module Frontend exposing (Model, app)

update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        Increment ->
            ( { model | counter = model.counter + 1 }, sendToBackend CounterIncremented )


        Reset -> ( { model | counter = 0 }, sendToBackend CounterReset )

        Decrement ->
            ( { model | counter = model.counter - 1 }, sendToBackend CounterDecremented )

        FNoop ->
            ( model, Cmd.none )
"""


under2 =
    """case msg of
        Increment ->
            ( { model | counter = model.counter + 1 }, sendToBackend CounterIncremented )

        Decrement ->
            ( { model | counter = model.counter - 1 }, sendToBackend CounterDecremented )

        FNoop ->
            ( model, Cmd.none )"""
