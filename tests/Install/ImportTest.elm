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

        -- |> Run.withOnly
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