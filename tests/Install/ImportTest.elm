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
        ]



-- test 1 - add simple import


test1 : { description : String, src : String, rule : Rule, under : String, fixed : String, message : String }
test1 =
    { description = "add simple import"
    , src = src1
    , rule = rule1
    , under = under1
    , fixed = fixed1
    , message = "moduleToImport: \"Dict\""
    }


rule1 : Rule
rule1 =
    Install.Import.init "Main" "Dict"
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
    , message = "moduleToImport: \"Dict\""
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
    , message = "moduleToImport: \"Dict\""
    }


rule2 : Rule
rule2 =
    Install.Import.init "Main" "Dict"
        |> Install.Import.withAlias "D"
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
    , message = "moduleToImport: \"Dict\""
    }


rule3 : Rule
rule3 =
    Install.Import.init "Main" "Dict"
        |> Install.Import.withExposedValues [ "Dict" ]
        |> Install.Import.makeRule


fixed3 : String
fixed3 =
    """module Main exposing (..)

import Set
import Dict exposing (Dict)
foo = 1"""
