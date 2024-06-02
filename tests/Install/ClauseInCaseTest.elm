module Install.ClauseInCaseTest exposing (all)

import Install.ClauseInCase exposing (init, makeRule)
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.ClauseInCase1"
        [ Run.expectNoErrorsTest "should not report an error when REPLACEME" src1 rule1
        , Run.expectErrorsTest "should report an error when REPLACEME" src1 rule1
        ]


rule1 =
    init "REPLACEME" "REPLACEME" "REPLACEME" "REPLACEME"
        |> makeRule


src1 =
    """module A exposing (..)
a = 1
"""
