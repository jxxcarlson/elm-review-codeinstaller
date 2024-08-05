module Install.TypeVariant exposing (config, Config)

{-| Add a variant to a given type in a given module. As in
the `ReviewConfig` item below, you specify the module name, the type
name, and the type of the new variant.

    Install.TypeVariant.config
        "Types"
        "ToBackend"
        [ "ResetCounter" "SetCounter Int" ]
        |> Install.addTypeVariant

Then you will have

     type ToBackend
         = CounterIncremented
         | CounterDecremented
         | ResetCounter
         | SetCounter Int

where the last two variants are the ones added.

@docs config, Config

-}

import Install.Internal.TypeVariant as Internal


{-| Configuration for rule.
-}
type alias Config =
    Internal.Config


{-| Create a rule that adds variants to a type in a specified module:

    Install.TypeVariant.config
        "Types"
        "ToBackend"
        [ "ResetCounter", "SetCounter: Int" ]
        |> Install.addTypeVariant

-}
config : String -> String -> List String -> Config
config hostModuleName typeName variants =
    Internal.Config
        { hostModuleName = String.split "." hostModuleName
        , typeName = typeName
        , variants = variants
        }
