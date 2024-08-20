module Install.Function.ReplaceFunction exposing (Config, config)

{-| Replace a function in a given module with a new implementation.

    -- code for ReviewConfig.elm:
    rule =
        Install.Function.ReplaceFunction.config
            "Frontend"
            "view"
            """view model =
            Html.text "This is a test\""""
            |> Install.replaceFunction

Running this rule will replace the function `view` in the module `Frontend` with the provided implementation.

The form of the rule is the same for nested modules:

    rule =
        Install.Function.ReplaceFunction.config
            "Foo.Bar"
            "earnInterest"
            "hoho model = { model | interest = 1.03 * model.interest }"
            |> Install.replaceFunction

@docs Config, config

-}

import Install.Internal.ReplaceFunction as Internal


{-| Configuration for rule: replace a function in a specified module with a new implementation.
-}
type alias Config =
    Internal.Config


{-| Initialize the configuration for the rule.
-}
config : String -> String -> String -> Config
config hostModuleName functionName functionImplementation =
    Internal.Config
        { hostModuleName = String.split "." hostModuleName
        , functionName = functionName
        , functionImplementation = functionImplementation
        }
