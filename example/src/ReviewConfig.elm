module ReviewConfig exposing (config)


import Review.Rule exposing (Rule)


{-| The first three rules in the config file add variants to somoe
of the types defined in module `Types`. The last two rules add
code to the 'init' and `updateFromFrontend` function of the`Backend` module.
-}
config : List Rule
config =
    [
    ]
