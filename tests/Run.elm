module Run exposing (expectNoErrorsTest, testFix)

import Review.Rule exposing (Rule)
import Review.Test
import Test exposing (Test, test)


expectNoErrorsTest : String -> String -> Rule -> Test
expectNoErrorsTest description src rule =
    test description <|
        \() ->
            src
                |> Review.Test.run rule
                |> Review.Test.expectNoErrors


type alias TestData =
    { description : String
    , src : String
    , rule : Rule
    , under : String
    , fixed : String
    , message : String
    }


testFix : TestData -> Test
testFix { description, src, rule, under, fixed, message } =
    test description <|
        \() ->
            src
                |> Review.Test.run rule
                |> Review.Test.expectErrors
                    [ Review.Test.error { message = message, details = [ "" ], under = under }
                        |> Review.Test.whenFixed fixed
                    ]
