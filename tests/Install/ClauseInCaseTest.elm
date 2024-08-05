module Install.ClauseInCaseTest exposing (all)

import Install
import Install.ClauseInCase exposing (config)
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.ClauseInCase1"
        [ Run.expectNoErrorsTest_ "should not report an error when REPLACEME" src1 rule1
        , Run.expectErrorsTest "should report an error when REPLACEME" src1 rule1
        ]


rule1 =
    config "REPLACEME" "REPLACEME" "REPLACEME" "REPLACEME"
        |> Install.insertClauseInCase


src1 =
    """module A exposing (..)
a = 1
"""
