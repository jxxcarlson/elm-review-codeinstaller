module Install.ElementToList exposing (add, Config)

{-|

@docs add, Config

-}

import Install.Internal.ElementToList as Internal


{-| Configuration for rule.
-}
type alias Config =
    Internal.Config


{-| Create a rule that adds elements to a list.

For example, the rule

    Install.Rule.rule
        [ Install.ElementToList.add
            "User"
            "userTypes"
            [ "Admin", "SystemAdmin" ]
            |> Install.Rule.addElementToList
        ]

results in the following fix for function `User.userTypes`:

    [ Standard ] -> [ Standard, Admin, SystemAdmin ]

-}
add : String -> String -> List String -> Config
add hostModuleName functionName elements =
    Internal.Config
        { hostModuleName = String.split "." hostModuleName
        , functionName = functionName
        , elements = elements
        }
