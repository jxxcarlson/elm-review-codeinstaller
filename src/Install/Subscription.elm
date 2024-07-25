module Install.Subscription exposing (config, Config)

{-| Use this rule to add to the list of subscriptions.

@docs config, Config

-}

import Install.Internal.Subscription as Internal


{-| Configuration for rule.
-}
type alias Config =
    Internal.Config


{-| Suppose that you have the following code in your `Backend.elm` file:

    subscriptions =
        Sub.batch [ foo, bar ]

and that you want to add `baz` to the list. To do this, say

    Install.Subscription.config "Backend" [ "baz" ]
        |> Install.subscription

The result is

    subscriptions =
        Sub.batch [ foo, bar, baz ]

-}
config : String -> List String -> Config
config hostModuleName subscriptions =
    Internal.Config
        { hostModuleName = String.split "." hostModuleName
        , subscriptions = subscriptions
        }
