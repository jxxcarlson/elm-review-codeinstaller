module Install.ImportTest exposing (..)

import Install.Import
import Review.Rule exposing (Rule)
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.Import"
        [ Run.testFix test1
        , Run.testFix test1a
        , Run.testFix test2
        , Run.testFix test3
        , Run.testFix test4
        , Run.expectNoErrorsTest test5.description test5.src test5.rule
        , Run.testFix test6
        , Run.testFix test7
        ]



-- test 1 - add simple import


test1 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test1 =
    { description = "add simple import"
    , src = src1
    , rule = rule1
    , under = under1
    , fixed = fixed1
    , message = "add 1 import to module Main"
    }


rule1 : Rule
rule1 =
    Install.Import.init "Main" [ { moduleToImport = "Dict", alias_ = Nothing, exposedValues = Nothing } ]
        |> Install.Import.makeRule


src1 : String
src1 =
    """module Main exposing (..)

import Set

foo = 1"""


under1 : String
under1 =
    """import Set"""


fixed1 : String
fixed1 =
    """module Main exposing (..)

import Set
import Dict
foo = 1"""



-- test 1a - add simple import when there are no imports


test1a : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test1a =
    { description = "add simple import when there are no imports"
    , src = src1a
    , rule = rule1
    , under = under1a
    , fixed = fixed1a
    , message = "add 1 import to module Main"
    }


src1a : String
src1a =
    """module Main exposing (..)

foo = 1"""


under1a : String
under1a =
    "module Main exposing (..)"


fixed1a : String
fixed1a =
    """module Main exposing (..)
import Dict
foo = 1"""



-- test 2 - add import with alias


test2 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test2 =
    { description = "add import with alias"
    , src = src1
    , rule = rule2
    , under = under1
    , fixed = fixed2
    , message = "add 1 import to module Main"
    }


rule2 : Rule
rule2 =
    Install.Import.init "Main" [ { moduleToImport = "Dict", alias_ = Just "D", exposedValues = Nothing } ]
        |> Install.Import.makeRule


fixed2 : String
fixed2 =
    """module Main exposing (..)

import Set
import Dict as D
foo = 1"""



-- test 3 - add import exposing


test3 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test3 =
    { description = "add import exposing"
    , src = src1
    , rule = rule3
    , under = under1
    , fixed = fixed3
    , message = "add 1 import to module Main"
    }


rule3 : Rule
rule3 =
    Install.Import.init "Main" [ { moduleToImport = "Dict", alias_ = Nothing, exposedValues = Just [ "Dict" ] } ]
        |> Install.Import.makeRule


fixed3 : String
fixed3 =
    """module Main exposing (..)

import Set
import Dict exposing (Dict)
foo = 1"""



-- Test 4 - add multiple imports with aliases and exposed values


test4 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test4 =
    { description = "add multiple imports with aliases and exposed values"
    , src = src1
    , rule = rule4
    , under = under1
    , fixed = fixed4
    , message = "add 5 imports to module Main"
    }


rule4 : Rule
rule4 =
    Install.Import.init "Main"
        [ { moduleToImport = "Dict", alias_ = Just "D", exposedValues = Just [ "Dict" ] }
        , { moduleToImport = "Html", alias_ = Nothing, exposedValues = Just [ "div" ] }
        , { moduleToImport = "Html.Attributes", alias_ = Just "Attributes", exposedValues = Just [ "class, style, disabled, href, title, type_, name, novalidate, pattern, readonly, required, size, for, form, max, min, step, cols, rows, wrap" ] }
        , { moduleToImport = "Pages.NestedModule.EvenMoreNested.MyPage", alias_ = Just "MyPage", exposedValues = Nothing }
        , { moduleToImport = "Array", alias_ = Nothing, exposedValues = Just [ "Array" ] }
        ]
        |> Install.Import.makeRule


fixed4 : String
fixed4 =
    """module Main exposing (..)

import Set
import Dict as D exposing (Dict)
import Html exposing (div)
import Html.Attributes as Attributes exposing (class, style, disabled, href, title, type_, name, novalidate, pattern, readonly, required, size, for, form, max, min, step, cols, rows, wrap)
import Pages.NestedModule.EvenMoreNested.MyPage as MyPage
import Array exposing (Array)
foo = 1"""



-- TEST 5 - should not report an error when import already exists


test5 : { description : String, src : String, rule : Rule }
test5 =
    { description = "should not report an error when import already exists"
    , src = src1
    , rule = rule5
    }


rule5 : Rule
rule5 =
    Install.Import.init "Main"
        [ { moduleToImport = "Set", alias_ = Nothing, exposedValues = Nothing }
        ]
        |> Install.Import.makeRule



-- Test 6 - Should show correct number of imports to add when repeated imports are ignored


test6 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test6 =
    { description = "Should show correct number of imports to add when repeated importes are ignored"
    , src = src1
    , rule = rule6
    , under = under1
    , fixed = fixed6
    , message = "add 1 import to module Main"
    }


rule6 : Rule
rule6 =
    Install.Import.init "Main"
        [ { moduleToImport = "Set", alias_ = Nothing, exposedValues = Nothing }
        , { moduleToImport = "Dict", alias_ = Nothing, exposedValues = Nothing }
        ]
        |> Install.Import.makeRule


fixed6 : String
fixed6 =
    """module Main exposing (..)

import Set
import Dict
foo = 1"""


test7 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test7 =
    { description = "Should show correct number of imports to add when repeated imports are ignored"
    , src = src1
    , rule = rule7
    , under = under1
    , fixed = fixed7
    , message = "add 1 import to module Main" --"Add Set and Dict to module Main using initSimple"
    }


rule7 : Rule
rule7 =
    Install.Import.initSimple "Main" [ "Set", "Dict" ] |> Install.Import.makeRule


fixed7 : String
fixed7 =
    """module Main exposing (..)

import Set
import Dict
foo = 1"""
