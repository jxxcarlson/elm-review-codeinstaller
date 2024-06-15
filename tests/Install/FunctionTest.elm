module Install.FunctionTest exposing (all)

import Install.Function
import Review.Rule exposing (Rule)
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.Function"
        [ Run.testFix test1
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
    Install.Function.init
        [ "Frontend" ]
        "view"
        """view model =
   Html.text "This is a test\""""
        |> Install.Function.makeRule


src1 : String
src1 =
    """module Frontend exposing(..)

view model =
   Html.div [] [ Html.text "Hello, World!" ]"""


under1 : String
under1 =
    """view model =
   Html.div [] [ Html.text "Hello, World!" ]"""


fixed1 : String
fixed1 =
    """module Frontend exposing(..)

view model =
   Html.text "This is a test\""""
