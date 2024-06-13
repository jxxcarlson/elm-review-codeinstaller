module Install.ClauseInCaseTest2 exposing (all)

import Install.ClauseInCase
import Review.Rule exposing (Rule)
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.ClauseInCase"
        [ Run.testFix test1a
        , Run.testFix test1b
        , Run.testFix test1c
        , Run.testFix test2
        , Run.testFix test3
        , Run.testFix test4
        , Run.testFix test5
        , Run.testFix test6
        , Run.testFix test7
        , Run.testFix test8
        , Run.testFix test9
        , Run.testFix test10
        ]



-- TEST 1


test1a : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test1a =
    { description = "Test 1a, simple makeRule: should report an error and fix it"
    , src = src1
    , rule = rule1a
    , under = under1
    , fixed = fixed1
    , message = "Add handler for ResetCounter"
    }


test1b : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test1b =
    { description = "Test 1b, withInsertAfter CounterIncremented: should report an error and fix it"
    , src = src1
    , rule = rule1b
    , under = under1
    , fixed = fixed1
    , message = "Add handler for ResetCounter"
    }


test1c : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test1c =
    { description = "Test 1c, withInsertAtBeginning: should report an error and fix it"
    , src = src1
    , rule = rule1c
    , under = under1
    , fixed = fixed1c
    , message = "Add handler for ResetCounter"
    }


rule1a : Rule
rule1a =
    Install.ClauseInCase.init "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.makeRule


rule1b : Rule
rule1b =
    Install.ClauseInCase.init "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.withInsertAfter "CounterIncremented"
        |> Install.ClauseInCase.makeRule


rule1c : Rule
rule1c =
    Install.ClauseInCase.init "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
        |> Install.ClauseInCase.withInsertAtBeginning
        |> Install.ClauseInCase.makeRule


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


test2 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test2 =
    { description = "Test 2 (Reset, Frontend.update): should report an error and fix it"
    , src = src2
    , rule = rule2
    , under = under2
    , fixed = fixed2
    , message = "Add handler for Reset"
    }


rule2 : Rule
rule2 =
    Install.ClauseInCase.init "Frontend" "update" "Reset" "( { model | counter = 0 }, sendToBackend CounterReset )"
        |> Install.ClauseInCase.withInsertAfter "Increment"
        |> Install.ClauseInCase.makeRule


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


test3 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test3 =
    { description = "Test 2: should escape string pattern when is a case of string patterns"
    , src = src3
    , rule = rule3
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


rule3 : Rule
rule3 =
    Install.ClauseInCase.init "Philosopher" "stringToPhilosopher" "Aspasia" "Just Aspasia"
        |> Install.ClauseInCase.withInsertAfter "Aristotle"
        |> Install.ClauseInCase.makeRule


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


test4 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test4 =
    { description = "Test 4: should add clause when case is inside let in expression"
    , src = src4
    , rule = rule4
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


rule4 : Rule
rule4 =
    Install.ClauseInCase.init "Elm.Syntax.Pattern2" "isStringPattern" "_" "False"
        |> Install.ClauseInCase.makeRule


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


test5 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test5 =
    { description = "Test 5: should add clause when case is inside tupled expression"
    , src = src5
    , rule = rule5
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


rule5 : Rule
rule5 =
    Install.ClauseInCase.init "SomeElmReviewRule" "errorFix" "Just \"\"" "[]"
        |> Install.ClauseInCase.withInsertAtBeginning
        |> Install.ClauseInCase.withCustomErrorMessage "Add handler for empty error string" [ "" ]
        |> Install.ClauseInCase.makeRule


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


test6 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test6 =
    { description = "Test 6: should add clause when case is inside parenthesized expression"
    , src = src6
    , rule = rule6
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


rule6 : Rule
rule6 =
    Install.ClauseInCase.init "WeekShiftForm" "getShiftFormFromWeekday" "Sun" ".sunday"
        |> Install.ClauseInCase.withInsertAfter "Sat"
        |> Install.ClauseInCase.makeRule


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


test7 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test7 =
    { description = "Test 7: should add clause when case is inside if block"
    , src = src7
    , rule = rule7
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


rule7 : Rule
rule7 =
    Install.ClauseInCase.init "Backend" "someFunction" "Just []" "Result.Err \"Empty data\""
        |> Install.ClauseInCase.withInsertAtBeginning
        |> Install.ClauseInCase.makeRule


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


test8 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test8 =
    { description = "Test 8: should add clause when case is inside application"
    , src = src8
    , rule = rule8
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


rule8 : Rule
rule8 =
    Install.ClauseInCase.init "WeekShiftForm" "getShiftFormFromWeekday" "Sun" ".sunday"
        |> Install.ClauseInCase.withInsertAfter "Sat"
        |> Install.ClauseInCase.makeRule


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


test9 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test9 =
    { description = "Test 9: should add clause when case is inside operator application and Lambda Expression"
    , src = src9
    , rule = rule9
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


rule9 : Rule
rule9 =
    Install.ClauseInCase.init "Errors" "decodeFieldErrors" "Just []" "Dict.singleton \"base\" []"
        |> Install.ClauseInCase.withInsertAtBeginning
        |> Install.ClauseInCase.makeRule


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


test10 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test10 =
    { description = "Test 10: should add clause when case is inside list expression"
    , src = src10
    , rule = rule10
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


rule10 : Rule
rule10 =
    Install.ClauseInCase.init "Modal" "viewModal" "ModalConfirm" "div [class \"modal-confirm\"] []"
        |> Install.ClauseInCase.makeRule


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
