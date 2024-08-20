module Install.Initializer exposing (config, Config)

{-| Add field = value pairs to the body of a function like `init` in which the
the return value is of the form `( SomeTypeAlias, Cmd msg )`. As in
the `ReviewConfig` item below, you specify the module name, the function
name, as well as a list of item `{field = <fieldName>, value = <value>}`
to be added to the function.

    Install.Initializer.config "Main"
        "init"
        [ { field = "message", value = "\"hohoho!\"" }, { field = "counter", value = "0" } ]
        |> Install.initializer

Thus we will have

     init : ( Model, Cmd BackendMsg )
     init =
         ( { counter = 0
           , message = "hohoho!"
           , counter = 0
           }
         , Cmd.none
         )

@docs config, Config

-}

import Install.Internal.Initializer as Internal


{-| Configuration for rule.
-}
type alias Config =
    Internal.Config


{-| Create a rule that adds fields to the body of a function like
`init` in which the return value is of the form `( Model, Cmd msg )`.
As in the `ReviewConfig` item below, you specify
the module name, the function name, as well as the
field name and value to be added to the function:

    Install.Initializer.config "Main"
        "init"
        [ { field = "message", value = "\"hohoho!\"" }, { field = "counter", value = "0" } ]
        |> Install.initializer

-}
config : String -> String -> List { field : String, value : String } -> Config
config hostModuleName functionName data =
    Internal.Config
        { hostModuleName = String.split "." hostModuleName
        , functionName = functionName
        , data = data
        }
