module Install.ElementToListTest exposing (all)

import Install.ElementToList exposing (makeRule)
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.ElementToList"
        [ Run.testFix test1
        , Run.expectNoErrorsTest "should not report error when the field already exists" src0 rule1
        , Run.testFix test2
        --, Run.testFix test3
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
    , rule = rule1
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
    makeRule "Contributors" "contributors" [ "Matt" ]


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
    , rule = rule2
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
    makeRule "Contributors" "contributors" [ "Matt", "Laozi" ]


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

-- TEST 3



test3 =
    { description = "should add multiple elements to the list in project with two modules"
    , src = src3
    , rule = rule3
    , under = under3
    , fixed = fixed3
    , message = "Add 2 elements to the list in project with two modules"
    }


src3 =
    """module Contributors exposing (..)

type Contributors
    = Jxx
    | Matt
    | Laozi

contributors : List Contributors
contributors =
    [ Jxx ]

 module Foo exposing(..)

 bar = 1
"""


rule3 =
    makeRule "Contributors" "contributors" [ "Matt", "Laozi" ]


under3 =
    """[ Jxx ]"""


fixed3 =
    """module Contributors exposing (..)

type Contributors
    = Jxx
    | Matt
    | Laozi

contributors : List Contributors
contributors =
    [ Jxx, Matt, Laozi ]
"""
