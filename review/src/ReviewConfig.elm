module ReviewConfig exposing (config)

import Review.Rule exposing (Rule)
import NoDebug.Log
import NoUnused.Dependencies
import NoDebug.TodoOrToString
import NoUnused.Variables

config : List Rule
config =
    [ NoUnused.Dependencies.rule
    , NoUnused.Variables.rule

    --, SetupProgramTest.rule
    ]
