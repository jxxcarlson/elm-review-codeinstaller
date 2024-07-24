module Install.ElementToListTest exposing (all)

import Install.ElementToList as ElementToList
import Install.Rule
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.ElementToList"
        [ Run.testFix_ test1
        , Run.expectNoErrorsTest_ "should not report error when the field already exists" src0 rule1
        , Run.testFix_ test2
        , Run.testFix_ test4
        ]



-- test0 - should not report error when the field already exists


src0 =
    """module Contributors exposing (..)

type Contributors
    = Jxx
    | Matt

contributors : List Contributors
contributors =
    [ Jxx, Matt ]
"""



-- test1 - should add element to the list


test1 =
    { description = "should add element to the list"
    , src = src1
    , installation = rule1
    , under = under1
    , fixed = fixed1
    , message = "Add 1 element to the list"
    }


src1 =
    """module Contributors exposing (..)

type Contributors
    = Jxx
    | Matt

contributors : List Contributors
contributors =
    [ Jxx ]
"""


rule1 =
    ElementToList.add "Contributors" "contributors" [ "Matt" ]
        |> Install.Rule.addElementToList


under1 =
    """[ Jxx ]"""


fixed1 =
    """module Contributors exposing (..)

type Contributors
    = Jxx
    | Matt

contributors : List Contributors
contributors =
    [ Jxx, Matt ]
"""



-- test2 - should add multiple elements to the list


test2 =
    { description = "should add multiple elements to the list"
    , src = src2
    , installation = rule2
    , under = under2
    , fixed = fixed2
    , message = "Add 2 elements to the list"
    }


src2 =
    """module Contributors exposing (..)

type Contributors
    = Jxx
    | Matt
    | Laozi

contributors : List Contributors
contributors =
    [ Jxx ]
"""


rule2 =
    ElementToList.add
        "Contributors"
        "contributors"
        [ "Matt", "Laozi" ]
        |> Install.Rule.addElementToList


under2 =
    """[ Jxx ]"""


fixed2 =
    """module Contributors exposing (..)

type Contributors
    = Jxx
    | Matt
    | Laozi

contributors : List Contributors
contributors =
    [ Jxx, Matt, Laozi ]
"""



-- TEST 4


test4 =
    { description = "should add an element to a list of tuples in project"
    , src = src4
    , installation = rule4
    , under = under4
    , fixed = fixed4
    , message = "Add 2 elements to the list"
    }


src4 =
    """module Routes exposing (..)

type Route
    = HomepageRoute
    | Quotes

routesAndNames : List (Route, String)
routesAndNames =
    [(HomepageRoute, "homepage")]
"""


rule4 =
    ElementToList.add
        "Routes"
        "routesAndNames"
        [ "(Quotes, \"quotes\")" ]
        |> Install.Rule.addElementToList


under4 =
    """[(HomepageRoute, "homepage")]"""


fixed4 =
    """module Routes exposing (..)

type Route
    = HomepageRoute
    | Quotes

routesAndNames : List (Route, String)
routesAndNames =
    [(HomepageRoute, "homepage"), (Quotes, "quotes")]
"""
