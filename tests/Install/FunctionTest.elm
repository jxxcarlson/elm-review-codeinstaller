module Install.FunctionTest exposing (all)

import Install exposing (Installation)
import Install.Function.InsertFunction as InsertFunction
import Install.Function.ReplaceFunction as ReplaceFunction
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.Function"
        [ Run.testFix_ test1
        , Run.testFix_ test1b
        , Run.testFix_ test2
        , Run.testFix_ test2a
        , Run.testFix_ test3
        , Run.testFix_ test4
        , Run.testFix_ test4a
        , Run.testFix_ test4b
        , Run.testFix_ test4c
        ]



-- TEST 1


test1 : { description : String, src : String, installation : Installation, under : String, fixed : String, message : String }
test1 =
    { description = "Test 1, replace function body of of Frontend.view"
    , src = src1
    , installation = rule1
    , under = under1
    , fixed = fixed1
    , message = "Replace function \"view\""
    }


rule1 : Installation
rule1 =
    ReplaceFunction.config
        "Frontend"
        "view"
        """view model =
    Html.text "This is a test\""""
        |> Install.function


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


test1b : { description : String, src : String, installation : Installation, under : String, fixed : String, message : String }
test1b =
    { description = "Test 1b, replace function with unformatted code"
    , src = src1b
    , installation = rule1b
    , under = under1b
    , fixed = fixed1b
    , message = "Replace function \"makeLinks\""
    }


src1b =
    """module View.Main exposing (view)

import Browser
import Element exposing (Element)
import Element.Background
import Element.Font
import Pages.Home
import Pages.Notes
import Route exposing (Route(..))
import String.Extra
import Types exposing (FrontendModel(..), FrontendMsg, LoadedModel)
import View.Color


noFocus : Element.FocusStyle
noFocus =
    { borderColor = Nothing
    , backgroundColor = Nothing
    , shadow = Nothing
    }

makeLinks : Types.LoadedModel -> Route -> List (Element msg)
makeLinks model route =
    homePageLink route
        :: List.map (makeLink route) Route.routesAndNames"""


rule1b : Installation
rule1b =
    ReplaceFunction.config
        "View.Main"
        "makeLinks"
        makeLinks
        |> Install.function


under1b : String
under1b =
    """makeLinks : Types.LoadedModel -> Route -> List (Element msg)
makeLinks model route =
    homePageLink route
        :: List.map (makeLink route) Route.routesAndNames"""


fixed1b : String
fixed1b =
    """module View.Main exposing (view)

import Browser
import Element exposing (Element)
import Element.Background
import Element.Font
import Pages.Home
import Pages.Notes
import Route exposing (Route(..))
import String.Extra
import Types exposing (FrontendModel(..), FrontendMsg, LoadedModel)
import View.Color


noFocus : Element.FocusStyle
noFocus =
    { borderColor = Nothing
    , backgroundColor = Nothing
    , shadow = Nothing
    }

makeLinks model route =
    case model.magicLinkModel.currentUserData of
        Just user ->
            homePageLink route
                :: List.map (makeLink route) (List.filter (\\(r, n) -> n /= "signin") Route.routesAndNames)

        Nothing ->
            homePageLink route
                :: List.map (makeLink route) Route.routesAndNames
 """


makeLinks =
    """makeLinks model route =
    case model.magicLinkModel.currentUserData of
        Just user ->
            homePageLink route
                :: List.map (makeLink route) (List.filter (\\(r, n) -> n /= "signin") Route.routesAndNames)

        Nothing ->
            homePageLink route
                :: List.map (makeLink route) Route.routesAndNames
 """



-- TEST 2 - Should add a new function


test2 : { description : String, src : String, installation : Installation, under : String, fixed : String, message : String }
test2 =
    { description = "Test 2, add a new function"
    , src = src1
    , installation = rule2
    , under = under2
    , fixed = fixed2
    , message = "Add function \"newFunction\""
    }


rule2 : Installation
rule2 =
    InsertFunction.config
        "Frontend"
        "newFunction"
        """newFunction model =
    Html.text "This is a test\""""
        |> Install.insertFunction


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



-- TEST 2A - should add new function with unformatted code


test2a : { description : String, src : String, installation : Installation, under : String, fixed : String, message : String }
test2a =
    { description = "Test 2a, add a new function with unformatted code"
    , src = src1
    , installation = rule2a
    , under = under2
    , fixed = fixed2a
    , message = "Add function \"makeLinks\""
    }


rule2a : Installation
rule2a =
    InsertFunction.config
        "Frontend"
        "makeLinks"
        makeLinks
        |> Install.insertFunction


fixed2a : String
fixed2a =
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
makeLinks model route =
    case model.magicLinkModel.currentUserData of
        Just user ->
            homePageLink route
                :: List.map (makeLink route) (List.filter (\\(r, n) -> n /= "signin") Route.routesAndNames)

        Nothing ->
            homePageLink route
                :: List.map (makeLink route) Route.routesAndNames
 """



-- TEST 3 - Should add a new function when there is no function in the module


test3 : { description : String, src : String, installation : Installation, under : String, fixed : String, message : String }
test3 =
    { description = "Test 3, add a new function when there is no function in the module"
    , src = src3
    , installation = rule3
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


rule3 : Installation
rule3 =
    InsertFunction.config
        "Frontend"
        "newFunction"
        """newFunction model =
    Html.text "This is a test\""""
        |> Install.insertFunction


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


test4 : { description : String, src : String, installation : Installation, under : String, fixed : String, message : String }
test4 =
    { description = "Test 4, add a new function after a specific function"
    , src = src1
    , installation = rule4
    , under = under4
    , fixed = fixed4
    , message = "Add function \"newFunction\""
    }


rule4 : Installation
rule4 =
    InsertFunction.config
        "Frontend"
        "newFunction"
        """newFunction model =
    Html.text "This is a test\""""
        |> InsertFunction.withInsertAfter "view"
        |> Install.insertFunction


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


test4a : { description : String, src : String, installation : Installation, under : String, fixed : String, message : String }
test4a =
    { description = "Test 4a, add a new function after a specific type"
    , src = src1
    , installation = rule4a
    , under = under4a
    , fixed = fixed4a
    , message = "Add function \"newFunction\""
    }


rule4a : Installation
rule4a =
    InsertFunction.config
        "Frontend"
        "newFunction"
        """newFunction model =
    Html.text "This is a test\""""
        |> InsertFunction.withInsertAfter "Model"
        |> Install.insertFunction


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


test4b : { description : String, src : String, installation : Installation, under : String, fixed : String, message : String }
test4b =
    { description = "Test 4b, add a new function after a specific type alias"
    , src = src3
    , installation = rule4b
    , under = under4b
    , fixed = fixed4b
    , message = "Add function \"newFunction\""
    }


rule4b : Installation
rule4b =
    InsertFunction.config
        "Frontend"
        "newFunction"
        """newFunction model =
    Html.text "This is a test\""""
        |> InsertFunction.withInsertAfter "Model"
        |> Install.insertFunction


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


test4c : { description : String, src : String, installation : Installation, under : String, fixed : String, message : String }
test4c =
    { description = "Test 4c, add a new function after a specific type alias"
    , src = src3
    , installation = rule4b
    , under = under4b
    , fixed = fixed4b
    , message = "Add function \"newFunction\""
    }
