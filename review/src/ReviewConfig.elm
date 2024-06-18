module ReviewConfig exposing (config)

import NoDebug.Log
import NoDebug.TodoOrToString
import NoUnused.Dependencies
import NoUnused.Variables
import Review.Rule exposing (Rule)


config : List Rule
config =
    [ NoUnused.Dependencies.rule
    , NoUnused.Variables.rule

    --, SetupProgramTest.rule
    ]
