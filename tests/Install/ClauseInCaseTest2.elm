module Install.ClauseInCaseTest2 exposing (all)

import Install exposing (Installation)
import Install.ClauseInCase
import Run exposing (TestData_)
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.ClauseInCase"
        [ Run.testFix_ test1a
        , Run.testFix_ test1b
        , Run.testFix_ test1c
        , Run.testFix_ test2
        , Run.testFix_ test3
        , Run.testFix_ test4
        , Run.testFix_ test5
        , Run.testFix_ test6
        , Run.testFix_ test7
        , Run.testFix_ test8
        , Run.testFix_ test9
        , Run.testFix_ test10
        ]



-- TEST 1


test1a : TestData_
test1a =
    { description = "Test 1a, simple makeRule: should report an error and fix it"
    , src = src1
    , installation = rule1a
    , under = under1
    , fixed = fixed1
    , message = "Add handler for ResetCounter"
    }


test1b : TestData_
test1b =
    { description = "Test 1b, withInsertAfter CounterIncremented: should report an error and fix it"
    , src = src1
    , installation = rule1b
    , under = under1
    , fixed = fixed1
    , message = "Add handler for ResetCounter"
    }


test1c : TestData_
test1c =
    { description = "Test 1c, withInsertAtBeginning: should report an error and fix it"
    , src = src1
    , installation = rule1c
    , under = under1
    , fixed = fixed1c
    , message = "Add handler for ResetCounter"
    }


rule1a : Installation
rule1a =
    Install.ClauseInCase.config "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.insertClauseInCase


rule1b : Installation
rule1b =
    Install.ClauseInCase.config "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.withInsertAfter "CounterIncremented"
        |> Install.insertClauseInCase


rule1c : Installation
rule1c =
    Install.ClauseInCase.config "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.withInsertAtBeginning
        |> Install.insertClauseInCase


src1 : String
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


fixed1 : String
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


fixed1c : String
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


under1 : String
under1 =
    """case msg of
        CounterIncremented ->
            let
                newCounter =
                    model.counter + 1
            in
            ( { model | counter = newCounter }, broadcast (CounterNewValue newCounter clientId) )"""



-- TEST 2


test2 : TestData_
test2 =
    { description = "Test 2 (Reset, Frontend.update): should report an error and fix it"
    , src = src2
    , installation = rule2
    , under = under2
    , fixed = fixed2
    , message = "Add handler for Reset"
    }


rule2 : Installation
rule2 =
    Install.ClauseInCase.config "Frontend" "update" "Reset" "( { model | counter = 0 }, sendToBackend CounterReset )"
        |> Install.ClauseInCase.withInsertAfter "Increment"
        |> Install.insertClauseInCase


src2 : String
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


fixed2 : String
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


under2 : String
under2 =
    """case msg of
        Increment ->
            ( { model | counter = model.counter + 1 }, sendToBackend CounterIncremented )

        Decrement ->
            ( { model | counter = model.counter - 1 }, sendToBackend CounterDecremented )

        FNoop ->
            ( model, Cmd.none )"""



-- TEST 3


test3 : TestData_
test3 =
    { description = "Test 2: should escape string pattern when is a case of string patterns"
    , src = src3
    , installation = rule3
    , under = under3
    , fixed = fixed3
    , message = "Add handler for Aspasia"
    }


src3 : String
src3 =
    """module Philosopher exposing (Philosopher(..), stringToPhilosopher)

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
                Nothing"""


rule3 : Installation
rule3 =
    Install.ClauseInCase.config "Philosopher" "stringToPhilosopher" "Aspasia" "Just Aspasia"
        |> Install.ClauseInCase.withInsertAfter "Aristotle"
        |> Install.insertClauseInCase


under3 : String
under3 =
    """case str of
            "Socrates" ->
                Just Socrates

            "Plato" ->
                Just Plato

            "Aristotle" ->
                Just Aristotle

            _ ->
                Nothing"""


fixed3 : String
fixed3 =
    """module Philosopher exposing (Philosopher(..), stringToPhilosopher)

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

            "Aspasia" -> Just Aspasia

            _ ->
                Nothing"""



-- TEST 4


test4 : TestData_
test4 =
    { description = "Test 4: should add clause when case is inside let in expression"
    , src = src4
    , installation = rule4
    , under = under4
    , fixed = fixed4
    , message = "Add handler for _"
    }


src4 : String
src4 =
    """module Elm.Syntax.Pattern2 exposing (..)

isStringPattern : Node Pattern -> Bool
isStringPattern nodePattern =
    let
        pattern = Node.value nodePattern
    in
    case pattern of
        StringPattern _ -> True
"""


rule4 : Installation
rule4 =
    Install.ClauseInCase.config "Elm.Syntax.Pattern2" "isStringPattern" "_" "False"
        |> Install.insertClauseInCase


under4 : String
under4 =
    """case pattern of
        StringPattern _ -> True"""


fixed4 : String
fixed4 =
    """module Elm.Syntax.Pattern2 exposing (..)

isStringPattern : Node Pattern -> Bool
isStringPattern nodePattern =
    let
        pattern = Node.value nodePattern
    in
    case pattern of
        StringPattern _ -> True

        _ -> False
"""



-- TEST 5


test5 : TestData_
test5 =
    { description = "Test 5: should add clause when case is inside tupled expression"
    , src = src5
    , installation = rule5
    , under = under5
    , fixed = fixed5
    , message = "Add handler for empty error string"
    }


src5 : String
src5 =
    """module SomeElmReviewRule exposing(..)

errorFix context node maybeError =
    (case maybeError of
        Just error ->
            [Rule.error error Node.range node]
        Nothing ->
            []
    , context)
    """


rule5 : Installation
rule5 =
    Install.ClauseInCase.config "SomeElmReviewRule" "errorFix" "Just \"\"" "[]"
        |> Install.ClauseInCase.withInsertAtBeginning
        |> Install.ClauseInCase.withCustomErrorMessage "Add handler for empty error string" [ "" ]
        |> Install.insertClauseInCase


under5 : String
under5 =
    """case maybeError of
        Just error ->
            [Rule.error error Node.range node]
        Nothing ->
            []"""


fixed5 : String
fixed5 =
    """module SomeElmReviewRule exposing(..)

errorFix context node maybeError =
    (case maybeError of

        Just "" -> []
        Just error ->
            [Rule.error error Node.range node]
        Nothing ->
            []
    , context)
    """



-- TEST 6


test6 : TestData_
test6 =
    { description = "Test 6: should add clause when case is inside parenthesized expression"
    , src = src6
    , installation = rule6
    , under = under6
    , fixed = fixed6
    , message = "Add handler for Sun"
    }


src6 : String
src6 =
    """module WeekShiftForm exposing(..)

getShiftFormFromWeekday weekday =
    (case weekday of
        Mon ->
            .monday

        Tue ->
            .tuesday

        Wed ->
            .wednesday

        Thu ->
            .thursday

        Fri ->
            .friday

        Sat ->
            .saturday
    )"""


rule6 : Installation
rule6 =
    Install.ClauseInCase.config "WeekShiftForm" "getShiftFormFromWeekday" "Sun" ".sunday"
        |> Install.ClauseInCase.withInsertAfter "Sat"
        |> Install.insertClauseInCase


under6 : String
under6 =
    """case weekday of
        Mon ->
            .monday

        Tue ->
            .tuesday

        Wed ->
            .wednesday

        Thu ->
            .thursday

        Fri ->
            .friday

        Sat ->
            .saturday"""


fixed6 : String
fixed6 =
    """module WeekShiftForm exposing(..)

getShiftFormFromWeekday weekday =
    (case weekday of
        Mon ->
            .monday

        Tue ->
            .tuesday

        Wed ->
            .wednesday

        Thu ->
            .thursday

        Fri ->
            .friday

        Sat ->
            .saturday

        Sun -> .sunday
    )"""



-- TEST 7 - IfBlock test


test7 : TestData_
test7 =
    { description = "Test 7: should add clause when case is inside if block"
    , src = src7
    , installation = rule7
    , under = under7
    , fixed = fixed7
    , message = "Add handler for Just []"
    }


src7 : String
src7 =
    """module Backend exposing (..)

someFunction : Bool -> Maybe Data -> Result String Data
someFunction condition maybeData =
    if condition then
        case maybeData of
            Just data ->
                Result.Ok data

            Nothing ->
                Result.Err "No data"
    else
        Result.Err "Condition not satisfied" """


rule7 : Installation
rule7 =
    Install.ClauseInCase.config "Backend" "someFunction" "Just []" "Result.Err \"Empty data\""
        |> Install.ClauseInCase.withInsertAtBeginning
        |> Install.insertClauseInCase


under7 : String
under7 =
    """case maybeData of
            Just data ->
                Result.Ok data

            Nothing ->
                Result.Err "No data\""""


fixed7 : String
fixed7 =
    """module Backend exposing (..)

someFunction : Bool -> Maybe Data -> Result String Data
someFunction condition maybeData =
    if condition then
        case maybeData of

            Just [] -> Result.Err "Empty data"
            Just data ->
                Result.Ok data

            Nothing ->
                Result.Err "No data"
    else
        Result.Err "Condition not satisfied" """



-- TEST 8 - Application test


test8 : TestData_
test8 =
    { description = "Test 8: should add clause when case is inside application"
    , src = src8
    , installation = rule8
    , under = under8
    , fixed = fixed8
    , message = "Add handler for Sun"
    }


src8 : String
src8 =
    """module WeekShiftForm exposing(..)
getShiftFormFromWeekday : Weekday -> WeekShiftForm -> ShiftForm
getShiftFormFromWeekday weekday weekShiftForm =
    (case weekday of
        Mon ->
            .monday

        Tue ->
            .tuesday

        Wed ->
            .wednesday

        Thu ->
            .thursday

        Fri ->
            .friday

        Sat ->
            .saturday
    )
        weekShiftForm"""


rule8 : Installation
rule8 =
    Install.ClauseInCase.config "WeekShiftForm" "getShiftFormFromWeekday" "Sun" ".sunday"
        |> Install.ClauseInCase.withInsertAfter "Sat"
        |> Install.insertClauseInCase


under8 : String
under8 =
    """case weekday of
        Mon ->
            .monday

        Tue ->
            .tuesday

        Wed ->
            .wednesday

        Thu ->
            .thursday

        Fri ->
            .friday

        Sat ->
            .saturday"""


fixed8 : String
fixed8 =
    """module WeekShiftForm exposing(..)
getShiftFormFromWeekday : Weekday -> WeekShiftForm -> ShiftForm
getShiftFormFromWeekday weekday weekShiftForm =
    (case weekday of
        Mon ->
            .monday

        Tue ->
            .tuesday

        Wed ->
            .wednesday

        Thu ->
            .thursday

        Fri ->
            .friday

        Sat ->
            .saturday

        Sun -> .sunday
    )
        weekShiftForm"""



-- TEST 9 - OperatorApplication and LambdaExpression test


test9 : TestData_
test9 =
    { description = "Test 9: should add clause when case is inside operator application and Lambda Expression"
    , src = src9
    , installation = rule9
    , under = under9
    , fixed = fixed9
    , message = "Add handler for Just []"
    }


src9 : String
src9 =
    """module Errors exposing (..)
decodeFieldErrors : Decoder FieldErrors
decodeFieldErrors =
    JsonD.field "errors" (JsonD.dict (JsonD.list JsonD.string))
        |> JsonD.maybe
        |> JsonD.andThen
            (\\maybeErrors ->
                case maybeErrors of
                    Just errors ->
                        JsonD.succeed errors

                    Nothing ->
                        JsonD.field "error_message" JsonD.string
                            |> JsonD.map
                                (\\message ->
                                    Dict.singleton "base" [ message ]
                                )
            )"""


rule9 : Installation
rule9 =
    Install.ClauseInCase.config "Errors" "decodeFieldErrors" "Just []" "Dict.singleton \"base\" []"
        |> Install.ClauseInCase.withInsertAtBeginning
        |> Install.insertClauseInCase


under9 : String
under9 =
    """case maybeErrors of
                    Just errors ->
                        JsonD.succeed errors

                    Nothing ->
                        JsonD.field "error_message" JsonD.string
                            |> JsonD.map
                                (\\message ->
                                    Dict.singleton "base" [ message ]
                                )"""


fixed9 : String
fixed9 =
    """module Errors exposing (..)
decodeFieldErrors : Decoder FieldErrors
decodeFieldErrors =
    JsonD.field "errors" (JsonD.dict (JsonD.list JsonD.string))
        |> JsonD.maybe
        |> JsonD.andThen
            (\\maybeErrors ->
                case maybeErrors of

                    Just [] -> Dict.singleton "base" []
                    Just errors ->
                        JsonD.succeed errors

                    Nothing ->
                        JsonD.field "error_message" JsonD.string
                            |> JsonD.map
                                (\\message ->
                                    Dict.singleton "base" [ message ]
                                )
            )"""



-- Test 10: ListExpression test


test10 : TestData_
test10 =
    { description = "Test 10: should add clause when case is inside list expression"
    , src = src10
    , installation = rule10
    , under = under10
    , fixed = fixed10
    , message = "Add handler for ModalConfirm"
    }


src10 : String
src10 =
    """module Modal exposing (..)

type Modal =
    ModalAlert
    | ModalForm
    | ModalConfirm -- newType

viewModal : Modal -> Html Msg
viewModal modal =
    div [class "modal-container"]
        [case modal of
            ModalAlert -> div [class "modal-alert"] []
            ModalForm -> div [class "modal-form"] []
        ]"""


rule10 : Installation
rule10 =
    Install.ClauseInCase.config "Modal" "viewModal" "ModalConfirm" "div [class \"modal-confirm\"] []"
        |> Install.insertClauseInCase


under10 : String
under10 =
    """case modal of
            ModalAlert -> div [class "modal-alert"] []
            ModalForm -> div [class "modal-form"] []"""


fixed10 : String
fixed10 =
    """module Modal exposing (..)

type Modal =
    ModalAlert
    | ModalForm
    | ModalConfirm -- newType

viewModal : Modal -> Html Msg
viewModal modal =
    div [class "modal-container"]
        [case modal of
            ModalAlert -> div [class "modal-alert"] []
            ModalForm -> div [class "modal-form"] []

            ModalConfirm -> div [class "modal-confirm"] []
        ]"""
