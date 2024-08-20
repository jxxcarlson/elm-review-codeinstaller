module Install.FieldInTypeAlias exposing (Config, config)

{-| Add a field to specified type alias
in a specified module. For example, if you put the code below in your
`ReviewConfig.elm` file, running `elm-review` will add the field
`quot: String` to the type alias `FrontendModel` in the `Types` module.

    -- code for ReviewConfig.elm:
    Install.FieldInTypeAlias.config "Types" "FrontendModel" [ "clientName: String", "quot: String" ]
        |> Install.fieldInTypeAlias

Thus we will have

    type alias FrontendModel =
        { counter : Int
        , clientId : String
        , clientName : String
        , quot : String
        }

@docs Config, config

-}

import Install.Internal.FieldInTypeAlias as Internal
import Set


{-| Configuration for rule.
-}
type alias Config =
    Internal.Config


{-| Create a rule that adds a field to a type alias in a specified module. Example usage:

    module Types exposing (FrontendModel)

    type alias FrontendModel =
        { counter : Int
        , clientId : String
        }

After running the rule with the following code:

    Install.FieldInTypeAlias.config "Types" "FrontendModel" [ "clientName: String", "quot: String" ]
        |> Install.fieldInTypeAlias

we will have

    type alias FrontendModel =
        { counter : Int
        , clientId : String
        , clientName : String
        , quot : String
        }

-}
config : String -> String -> List String -> Config
config hostModuleName typeName fieldDefinitions =
    Internal.Config
        { hostModuleName = String.split "." hostModuleName
        , typeName = typeName
        , fieldDefinitions = fieldDefinitions
        , fieldNames =
            List.map Internal.getFieldName fieldDefinitions
                |> Set.fromList
        }
