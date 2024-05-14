module ReviewConfig exposing (config)

import Install.ClauseInCase
import Install.FieldInTypeAlias
import Install.Initializer
import Install.TypeVariant
import Review.Rule exposing (Rule)


{-| The first three rules in the config file add variants to somoe
of the types defined in module `Types`. The last two rules add
code to the 'init' and `updateFromFrontend` function of the`Backend` module.
-}
config : List Rule
config =
    [ Install.TypeVariant.makeRule "Types" "ToBackend" "ResetCounter"
    , Install.FieldInTypeAlias.makeRule "Types" "FrontendModel" "message: String"
    , Install.Initializer.makeRule "Backend" "init" "message" "\"hohoho!\""
    , Install.ClauseInCase.makeRule
        "Backend"
        "updateFromFrontend"
        "ResetCounter"
        "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
    ]
