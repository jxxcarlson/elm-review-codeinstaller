module Install.ClauseInCaseTest exposing (all)

import Install.ClauseInCase exposing (init, makeRule)
import Review.Test
import Test exposing (Test, describe, test)


all : Test
all =
    let
        rule =
            init "REPLACEME" "REPLACEME" "REPLACEME" "REPLACEME"
                |> makeRule
    in
    describe "Install.ClauseInCase"
        [ test "should not report an error when REPLACEME" <|
            \() ->
                """module A exposing (..)
a = 1
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "should report an error when REPLACEME" <|
            \() ->
                """module A exposing (..)
a = 1
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "REPLACEME"
                            , details = [ "REPLACEME" ]
                            , under = "REPLACEME"
                            }
                        ]
        ]
