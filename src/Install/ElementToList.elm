module Install.ElementToList exposing (config, Config)

{-|

@docs config, Config

-}

import Install.Internal.ElementToList as Internal


{-| Configuration for rule.
-}
type alias Config =
    Internal.Config


{-| Create a rule that adds elements to a list.

For example, the rule

    Install.Rule.rule
        [ Install.ElementToList.config
            "User"
            "userTypes"
            [ "Admin", "SystemAdmin" ]
            |> Install.Rule.addElementToList
        ]

results in the following fix for function `User.userTypes`:

    [ Standard ] -> [ Standard, Admin, SystemAdmin ]

-}
config : String -> String -> List String -> Config
config hostModuleName functionName elements =
    Internal.Config
        { hostModuleName = String.split "." hostModuleName
        , functionName = functionName
        , elements = elements
        }
