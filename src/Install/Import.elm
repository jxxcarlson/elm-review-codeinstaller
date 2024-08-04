module Install.Import exposing
    ( config, Config
    , ImportData, module_, withAlias, withExposedValues, qualified
    )

{-| Add import statements to a given module.
For example, to add `import Foo.Bar` to the `Frontend` module, you can use the following configuration:

    Install.Rule.rule
        [ Install.Import.config "Frontend"
            [ Install.Import.module_ "Foo.Bar" ]
            |> Install.Rule.addImport
        ]

To add the statement `import Foo.Bar as FB exposing (a, b, c)` to the `Frontend` module, do this:

    Install.Import.config "Frontend"
        [ Install.Import.module_ "Foo.Bar"
            |> Install.Import.withAlias "FB"
            |> Install.Import.withExposedValues [ "a", "b", "c" ]
        ]

There is a shortcut for importing modules with no alias or exposed values

    Install.Import.qualified "Frontend"
        [ "Foo.Bar", "Baz.Qux" ]

@docs config, Config
@docs ImportData, module_, withAlias, withExposedValues, qualified

-}

import Install.Internal.Import as Internal


{-| Configuration for the rule.
-}
type alias Config =
    Internal.Config


{-| Initialize the configuration for the rule.
-}
config : String -> List { moduleToImport : String, alias : Maybe String, exposedValues : Maybe (List String) } -> Config
config hostModuleName_ imports =
    Internal.Config
        { hostModuleName = String.split "." hostModuleName_
        , imports = List.map (\{ moduleToImport, alias, exposedValues } -> { moduleToImport = String.split "." moduleToImport, alias = alias, exposedValues = exposedValues }) imports
        }


{-| The functions config and module\_ returns values of this type; The functions
withAlias and withExposedValues transform values of this type.
-}
type alias ImportData =
    { moduleToImport : String
    , alias : Maybe String
    , exposedValues : Maybe (List String)
    }


{-| Create a module to import with no alias or exposed values
-}
module_ : String -> ImportData
module_ name =
    { moduleToImport = name, alias = Nothing, exposedValues = Nothing }


{-| Add an alias to a module to import
-}
withAlias : String -> ImportData -> ImportData
withAlias alias importData =
    { importData | alias = Just alias }


{-| Add exposed values to a module to import
-}
withExposedValues : List String -> ImportData -> ImportData
withExposedValues exposedValues importData =
    { importData | exposedValues = Just exposedValues }


{-| Create a rule that adds import statements to a module with no alias or exposed values. Just pass the module name and the list of modules to import.
-}
qualified : String -> List String -> Config
qualified hostModuleName_ imports =
    Internal.Config
        { hostModuleName = String.split "." hostModuleName_
        , imports = List.map (\moduleToImport -> { moduleToImport = String.split "." moduleToImport, alias = Nothing, exposedValues = Nothing }) imports
        }
