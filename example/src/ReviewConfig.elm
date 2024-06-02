module ReviewConfig exposing (config)


import Review.Rule exposing (Rule)
import Install.TypeVariant
import Install.FieldInTypeAlias
import Install.Initializer
import Install.ClauseInCase





{-| The first three rules in the config file add variants to some
of the types defined in module `Types`. The last two rules add
code to the 'init' and `updateFromFrontend` function of the`Backend` module.
-}
config : List Rule
config =
    [ Install.TypeVariant.makeRule "Types" "ToBackend" "ResetCounter"
    , Install.FieldInTypeAlias.makeRule "Types" "FrontendModel" "message: String"
    , Install.Initializer.makeRule "Backend" "init" "message" "\"hohoho!\""
    , Install.ClauseInCase.init "Backend" "updateFromFrontend" "ResetCounter" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
              |> Install.ClauseInCase.makeRule
    ,  Install.ClauseInCase.init "Frontend" "update" "Reset" "( { model | counter = 0 }, sendToBackend CounterReset )"
              |> Install.ClauseInCase.withInsertAfter "Increment"
              |> Install.ClauseInCase.makeRule
    ]
