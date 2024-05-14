module ReviewConfig exposing (config)

import Review.Rule exposing (Rule)
import NoDebug.Log
import NoDebug.TodoOrToString


{-| The first three rules in the config file add variants to somoe
of the types defined in module `Types`. The last two rules add
code to the 'init' and `updateFromFrontend` function of the`Backend` module.
-}
config : List Rule
config =
    [ NoDebug.Log.rule
          , NoDebug.TodoOrToString.rule
              |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    ]
