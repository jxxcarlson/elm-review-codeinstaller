module Run exposing
    ( TestData
    , TestData_
    , expectErrorsTest
    , expectNoErrorsTest
    , expectNoErrorsTest_
    , testFix
    , testFix_
    , withOnly
    )

import Install
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


expectNoErrorsTest_ : String -> String -> Install.Installation -> Test
expectNoErrorsTest_ description src installation =
    test description <|
        \() ->
            src
                |> Review.Test.run (Install.rule "TestRule" [ installation ])
                |> Review.Test.expectNoErrors


expectErrorsTest : String -> String -> Install.Installation -> Test
expectErrorsTest description src installation =
    test description <|
        \() ->
            src
                |> Review.Test.run (Install.rule "TestRule" [ installation ])
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


type alias TestData_ =
    { description : String
    , src : String
    , installation : Install.Installation
    , under : String
    , fixed : String
    , message : String
    }


testFix_ : TestData_ -> Test
testFix_ { description, src, installation, under, fixed, message } =
    test description <|
        \() ->
            src
                |> Review.Test.run (Install.rule "TestRule" [ installation ])
                |> Review.Test.expectErrors
                    [ Review.Test.error { message = message, details = [ "" ], under = under }
                        |> Review.Test.whenFixed fixed
                    ]
