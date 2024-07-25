module Install.InitializerCmd exposing (config, Config)

{-| Consider a function whose return value is of the form `( _, Cmd.none )`.
Suppose given a list of commands, e.g. `[foo, bar]`. The function
`makeRule` described below replaces `Cmd.none` by `Cmd.batch [ foo, bar ]`.

@docs config, Config

-}

import Install.Internal.InitializerCmd as Internal


{-| Configuration for rule.
-}
type alias Config =
    Internal.Config


{-| Consider a function whose return value is of the form `( _, Cmd.none )`.
Suppose given a list of commands, e.g. `[foo, bar]`. The function
`makeRule` creates a rule that replaces `Cmd.none` by `Cmd.batch [ foo, bar ]`.
For example, the rule

    Install.InitializerCmd.config "A.B" "init" [ "foo", "bar" ]
        |> Install.initializerCmd

results in the following fix for function `A.B.init`:

    Cmd.none -> (Cmd.batch [ foo, bar ])

-}
config : String -> String -> List String -> Config
config hostModuleName functionName cmds =
    Internal.Config
        { hostModuleName = String.split "." hostModuleName
        , functionName = functionName
        , cmds = cmds
        }
