module Run exposing
    ( expectErrorsTest
    , expectNoErrorsTest
    , expectNoErrorsTest_
    , testFix
    , withOnly
    )

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


expectNoErrorsTest_ : TestData -> Test
expectNoErrorsTest_ testData =
    test testData.description <|
        \() ->
            testData.src
                |> Review.Test.run testData.rule
                |> Review.Test.expectNoErrors


expectErrorsTest : String -> String -> Rule -> Test
expectErrorsTest description src rule =
    test description <|
        \() ->
            src
                |> Review.Test.run rule
                |> Review.Test.expectErrors []


withOnly : Test -> Test
withOnly t =
    t |> Test.only


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
