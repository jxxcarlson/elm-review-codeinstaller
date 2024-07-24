module Install.ImportTest exposing (..)

import Install.Import exposing (module_, withAlias, withExposedValues)
import Install.Rule
import Review.Test
import Run exposing (TestData_)
import Test exposing (Test, describe, test)


all : Test
all =
    describe "Install.Import"
        [ Run.testFix_ test1
        , Run.testFix_ test1a
        , Run.testFix_ test2
        , Run.testFix_ test3
        , Run.testFix_ test4
        , Run.expectNoErrorsTest_ test5.description test5.src test5.installation
        , Run.testFix_ test6
        , Run.testFix_ test7
        , test "should not report an error when it's not the target module" <|
            \() ->
                """module NotMain exposing (..)

import Set

foo = 1"""
                    |> Review.Test.run (Install.Rule.rule "TestRule" [ rule1 ])
                    |> Review.Test.expectNoErrors
        ]



-- test 1 - add simple import


test1 : TestData_
test1 =
    { description = "add simple import"
    , src = src1
    , installation = rule1
    , under = under1
    , fixed = fixed1
    , message = "add 1 import to module Main"
    }


rule1 : Install.Rule.Installation
rule1 =
    Install.Import.config "Main" [ module_ "Dict" ]
        |> Install.Rule.addImport


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


test1a : TestData_
test1a =
    { description = "add simple import when there are no imports"
    , src = src1a
    , installation = rule1
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


test2 : TestData_
test2 =
    { description = "add import with alias"
    , src = src1
    , installation = rule2
    , under = under1
    , fixed = fixed2
    , message = "add 1 import to module Main"
    }


rule2 : Install.Rule.Installation
rule2 =
    Install.Import.config "Main" [ module_ "Dict" |> withAlias "D" ]
        |> Install.Rule.addImport


fixed2 : String
fixed2 =
    """module Main exposing (..)

import Set
import Dict as D
foo = 1"""



-- test 3 - add import exposing


test3 : TestData_
test3 =
    { description = "add import exposing"
    , src = src1
    , installation = rule3
    , under = under1
    , fixed = fixed3
    , message = "add 1 import to module Main"
    }


rule3 : Install.Rule.Installation
rule3 =
    Install.Import.config "Main" [ module_ "Dict" |> withExposedValues [ "Dict" ] ]
        |> Install.Rule.addImport


fixed3 : String
fixed3 =
    """module Main exposing (..)

import Set
import Dict exposing (Dict)
foo = 1"""



-- Test 4 - add multiple imports with aliases and exposed values


test4 : TestData_
test4 =
    { description = "add multiple imports with aliases and exposed values"
    , src = src1
    , installation = rule4
    , under = under1
    , fixed = fixed4
    , message = "add 5 imports to module Main"
    }


rule4 : Install.Rule.Installation
rule4 =
    Install.Import.config "Main"
        [ module_ "Dict" |> withAlias "D" |> withExposedValues [ "Dict" ]
        , module_ "Html" |> withExposedValues [ "div" ]
        , module_ "Html.Attributes" |> withAlias "Attributes" |> withExposedValues [ "class, style, disabled, href, title, type_, name, novalidate, pattern, readonly, required, size, for, form, max, min, step, cols, rows, wrap" ]
        , module_ "Pages.NestedModule.EvenMoreNested.MyPage" |> withAlias "MyPage"
        , module_ "Array" |> withExposedValues [ "Array" ]
        ]
        |> Install.Rule.addImport


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


test5 : { description : String, src : String, installation : Install.Rule.Installation }
test5 =
    { description = "should not report an error when import already exists"
    , src = src1
    , installation = rule5
    }


rule5 : Install.Rule.Installation
rule5 =
    Install.Import.config "Main"
        [ module_ "Set" ]
        |> Install.Rule.addImport



-- Test 6 - Should show correct number of imports to add when repeated imports are ignored


test6 : TestData_
test6 =
    { description = "Should show correct number of imports to add when repeated importes are ignored"
    , src = src1
    , installation = rule6
    , under = under1
    , fixed = fixed6
    , message = "add 1 import to module Main"
    }


rule6 : Install.Rule.Installation
rule6 =
    Install.Import.config "Main"
        [ module_ "Set"
        , module_ "Dict"
        ]
        |> Install.Rule.addImport


fixed6 : String
fixed6 =
    """module Main exposing (..)

import Set
import Dict
foo = 1"""


test7 : TestData_
test7 =
    { description = "Should show correct number of imports to add when repeated imports are ignored"
    , src = src1
    , installation = rule7
    , under = under1
    , fixed = fixed7
    , message = "add 2 imports to module Main" --"Add Set and Dict to module Main using initSimple"
    }


rule7 : Install.Rule.Installation
rule7 =
    Install.Import.qualified "Main" [ "Set", "Dict", "Foo.Bar" ] |> Install.Rule.addImport


fixed7 : String
fixed7 =
    """module Main exposing (..)

import Set
import Dict
import Foo.Bar
foo = 1"""
