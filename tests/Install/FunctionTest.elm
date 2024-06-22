module Install.FunctionTest exposing (all)

import Install.Function.InsertFunction as InsertFunction
import Install.Function.ReplaceFunction as ReplaceFunction
import Review.Rule exposing (Rule)
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.Function"
        [ Run.testFix test1
        , Run.testFix test2
        , Run.testFix test3
        , Run.testFix test4
        , Run.testFix test4a
        , Run.testFix test4b
        , Run.testFix test4c
        ]



-- TEST 1


test1 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test1 =
    { description = "Test 1, replace function body of of Frontend.view"
    , src = src1
    , rule = rule1
    , under = under1
    , fixed = fixed1
    , message = "Replace function \"view\""
    }


rule1 : Rule
rule1 =
    ReplaceFunction.init
        "Frontend"
        "view"
        """view model =
    Html.text "This is a test\""""
        |> ReplaceFunction.makeRule


src1 : String
src1 =
    """module Frontend exposing(..)

type Model = String

init string =
    (string, Cmd.none)

view model =
    Html.div [] [ Html.text "Hello, World!" ]

update msg model =
    case msg of
        _ ->
            model"""


under1 : String
under1 =
    """view model =
    Html.div [] [ Html.text "Hello, World!" ]"""


fixed1 : String
fixed1 =
    """module Frontend exposing(..)

type Model = String

init string =
    (string, Cmd.none)

view model =
    Html.text "This is a test"

update msg model =
    case msg of
        _ ->
            model"""



-- TEST 2 - Should add a new function


test2 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test2 =
    { description = "Test 2, add a new function"
    , src = src1
    , rule = rule2
    , under = under2
    , fixed = fixed2
    , message = "Add function \"newFunction\""
    }


rule2 : Rule
rule2 =
    InsertFunction.init
        "Frontend"
        "newFunction"
        """newFunction model =
    Html.text "This is a test\""""
        |> InsertFunction.makeRule


under2 : String
under2 =
    """update msg model =
    case msg of
        _ ->
            model"""


fixed2 : String
fixed2 =
    """module Frontend exposing(..)

type Model = String

init string =
    (string, Cmd.none)

view model =
    Html.div [] [ Html.text "Hello, World!" ]

update msg model =
    case msg of
        _ ->
            model
newFunction model =
    Html.text "This is a test\""""



-- TEST 3 - Should add a new function when there is no function in the module


test3 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test3 =
    { description = "Test 3, add a new function when there is no function in the module"
    , src = src3
    , rule = rule3
    , under = under3
    , fixed = fixed3
    , message = "Add function \"newFunction\""
    }


src3 : String
src3 =
    """module Frontend exposing(..)

import Html exposing (Html)
import Html.Attributes exposing (class)

type alias Model =
    {counter : Int}
"""


rule3 : Rule
rule3 =
    InsertFunction.init
        "Frontend"
        "newFunction"
        """newFunction model =
    Html.text "This is a test\""""
        |> InsertFunction.makeRule


under3 : String
under3 =
    """type alias Model =
    {counter : Int}"""


fixed3 : String
fixed3 =
    """module Frontend exposing(..)

import Html exposing (Html)
import Html.Attributes exposing (class)

type alias Model =
    {counter : Int}
newFunction model =
    Html.text "This is a test\""""



-- TEST 4 - Should add a new function after a specific function


test4 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test4 =
    { description = "Test 4, add a new function after a specific function"
    , src = src1
    , rule = rule4
    , under = under4
    , fixed = fixed4
    , message = "Add function \"newFunction\""
    }


rule4 : Rule
rule4 =
    InsertFunction.init
        "Frontend"
        "newFunction"
        """newFunction model =
    Html.text "This is a test\""""
        |> InsertFunction.withInsertAfter "view"
        |> InsertFunction.makeRule


under4 : String
under4 =
    """view model =
    Html.div [] [ Html.text "Hello, World!" ]"""


fixed4 : String
fixed4 =
    """module Frontend exposing(..)

type Model = String

init string =
    (string, Cmd.none)

view model =
    Html.div [] [ Html.text "Hello, World!" ]
newFunction model =
    Html.text "This is a test"
update msg model =
    case msg of
        _ ->
            model"""


test4a : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test4a =
    { description = "Test 4a, add a new function after a specific type"
    , src = src1
    , rule = rule4a
    , under = under4a
    , fixed = fixed4a
    , message = "Add function \"newFunction\""
    }


rule4a : Rule
rule4a =
    InsertFunction.init
        "Frontend"
        "newFunction"
        """newFunction model =
    Html.text "This is a test\""""
        |> InsertFunction.withInsertAfter "Model"
        |> InsertFunction.makeRule


under4a : String
under4a =
    """type Model = String"""


fixed4a : String
fixed4a =
    """module Frontend exposing(..)

type Model = String
newFunction model =
    Html.text "This is a test"
init string =
    (string, Cmd.none)

view model =
    Html.div [] [ Html.text "Hello, World!" ]

update msg model =
    case msg of
        _ ->
            model"""


test4b : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test4b =
    { description = "Test 4b, add a new function after a specific type alias"
    , src = src3
    , rule = rule4b
    , under = under4b
    , fixed = fixed4b
    , message = "Add function \"newFunction\""
    }


rule4b : Rule
rule4b =
    InsertFunction.init
        "Frontend"
        "newFunction"
        """newFunction model =
    Html.text "This is a test\""""
        |> InsertFunction.withInsertAfter "Model"
        |> InsertFunction.makeRule


under4b : String
under4b =
    """type alias Model =
    {counter : Int}"""


fixed4b : String
fixed4b =
    """module Frontend exposing(..)

import Html exposing (Html)
import Html.Attributes exposing (class)

type alias Model =
    {counter : Int}
newFunction model =
    Html.text "This is a test\""""


test4c : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test4c =
    { description = "Test 4c, add a new function after a specific type alias"
    , src = src3
    , rule = rule4b
    , under = under4b
    , fixed = fixed4b
    , message = "Add function \"newFunction\""
    }
