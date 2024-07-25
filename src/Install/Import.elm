module Install.Import exposing (config, ImportData, module_, withAlias, withExposedValues, qualified, makeRule)

{-| Add import statements to a given module.
For example, to add `import Foo.Bar` to the `Frontend` module, you can use the following configuration:

    Install.Import.config "Frontend"
        [ Install.Import.module_ "Foo.Bar" ]
        |> Install.Import.makeRule

To add the statement `import Foo.Bar as FB exposing (a, b, c)` to the `Frontend` module, do this:

    Install.Import.config "Frontend"
        [ Install.Import.module_ "Foo.Bar"
            |> Install.Import.withAlias "FB"
            |> Install.Import.withExposedValues [ "a", "b", "c" ]
        ]
        |> Install.Import.makeRule

There is a shortcut for importing modules with no alias or exposed values

    Install.Import.qualified "Frontend"
        [ Install.Import.module_ "Foo.Bar"
        , Install.Import.module_ "Baz.Qux"
        ]
        |> Install.Import.makeRule

@docs config, ImportData, module_, withAlias, withExposedValues, qualified, makeRule

-}

import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module exposing (Module)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range as Range exposing (Range)
import Review.Fix as Fix
import Review.Rule as Rule exposing (Error, Rule)


{-| Configuration for the rule.
-}
type Config
    = Config
        { hostModuleName : List String
        , imports : List ImportedModule
        , customErrorMessage : CustomError
        }


type alias ImportedModule =
    { moduleToImport : ModuleName
    , alias : Maybe String
    , exposedValues : Maybe (List String)
    }


{-| Custom error message to be displayed when running `elm-review --fix` or `elm-review --fix-all`
-}
type CustomError
    = CustomError { message : String, details : List String }


{-| Initialize the configuration for the rule.
-}
config : String -> List { moduleToImport : String, alias : Maybe String, exposedValues : Maybe (List String) } -> Config
config hostModuleName_ imports =
    Config
        { hostModuleName = String.split "." hostModuleName_
        , imports = List.map (\{ moduleToImport, alias, exposedValues } -> { moduleToImport = String.split "." moduleToImport, alias = alias, exposedValues = exposedValues }) imports
        , customErrorMessage = CustomError { message = "Install imports in module " ++ hostModuleName_, details = [ "" ] }
        }


{-| The functions config and module\_ returns values of this type; The functions
withAlias and withExposedValues transform values of this type.
-}
type alias ImportData =
    { moduleToImport : String
    , alias : Maybe String
    , exposedValues : Maybe (List String)
    }



--{ moduleToImport : String, alias : Maybe String, exposedValues : Maybe (List String) }


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


{-| Initialize the configuration for the rule.
-}
qualified : String -> List String -> Config
qualified hostModuleName_ imports =
    Config
        { hostModuleName = String.split "." hostModuleName_
        , imports = List.map (\moduleToImport -> { moduleToImport = String.split "." moduleToImport, alias = Nothing, exposedValues = Nothing }) imports
        , customErrorMessage = CustomError { message = "Install imports in module " ++ hostModuleName_, details = [ "" ] }
        }


{-| Create a rule that adds a list of imports for given modules in a given module.
See above for examples.
-}
makeRule : Config -> Rule
makeRule config_ =
    Rule.newModuleRuleSchemaUsingContextCreator "Install.Import" initialContext
        |> Rule.withImportVisitor (importVisitor config_)
        |> Rule.withModuleDefinitionVisitor moduleDefinitionVisitor
        |> Rule.withFinalModuleEvaluation (finalEvaluation config_)
        |> Rule.providesFixesForModuleRule
        |> Rule.fromModuleRuleSchema


type alias Context =
    { moduleName : ModuleName
    , moduleWasImported : Bool
    , lastNodeRange : Range
    , foundImports : List (List String)
    }


initialContext : Rule.ContextCreator () Context
initialContext =
    Rule.initContextCreator
        (\moduleName () -> { moduleName = moduleName, moduleWasImported = False, lastNodeRange = Range.empty, foundImports = [] })
        |> Rule.withModuleName


importVisitor : Config -> Node Import -> Context -> ( List (Error {}), Context )
importVisitor (Config config_) node context =
    case Node.value node |> .moduleName |> Node.value of
        currentModuleName ->
            let
                allModuleNames =
                    List.map .moduleToImport config_.imports

                foundImports =
                    context.foundImports ++ [ currentModuleName ]

                areAllImportsFound =
                    List.all (\importedModuleName -> List.member importedModuleName foundImports) allModuleNames
            in
            if areAllImportsFound && config_.hostModuleName == context.moduleName then
                ( [], { context | moduleWasImported = True, lastNodeRange = Node.range node } )

            else
                ( [], { context | lastNodeRange = Node.range node, foundImports = foundImports } )


moduleDefinitionVisitor : Node Module -> Context -> ( List (Error {}), Context )
moduleDefinitionVisitor def context =
    -- visit the module definition to set the module definition as the lastNodeRange in case the module has no imports yet
    ( [], { context | lastNodeRange = Node.range def } )


finalEvaluation : Config -> Context -> List (Rule.Error {})
finalEvaluation (Config config_) context =
    if context.moduleWasImported == False && config_.hostModuleName == context.moduleName then
        fixError config_.imports context

    else
        []


fixError : List ImportedModule -> Context -> List (Error {})
fixError imports context =
    let
        importText moduleToImport importedModuleAlias exposedValues =
            "import "
                ++ String.join "." moduleToImport
                |> addAlias importedModuleAlias
                |> addExposing exposedValues

        uniqueImports =
            List.filter (\importedModule -> not (List.member importedModule.moduleToImport context.foundImports)) imports

        allImports =
            List.map (\{ moduleToImport, alias, exposedValues } -> importText moduleToImport alias exposedValues) uniqueImports
                |> String.join "\n"

        addAlias : Maybe String -> String -> String
        addAlias mAlias str =
            case mAlias of
                Nothing ->
                    str

                Just alias ->
                    str ++ " as " ++ alias

        addExposing : Maybe (List String) -> String -> String
        addExposing mExposedValues str =
            case mExposedValues of
                Nothing ->
                    str

                Just exposedValues ->
                    str ++ " exposing (" ++ String.join ", " exposedValues ++ ")"

        numberOfImports =
            List.length uniqueImports

        moduleName =
            context.moduleName |> String.join "."

        numberOfImportsText =
            if numberOfImports == 1 then
                String.fromInt numberOfImports ++ " import"

            else
                String.fromInt numberOfImports ++ " imports"
    in
    [ Rule.errorWithFix
        { message = "add " ++ numberOfImportsText ++ " to module " ++ moduleName, details = [ "" ] }
        context.lastNodeRange
        [ Fix.insertAt { row = context.lastNodeRange.end.row + 1, column = context.lastNodeRange.end.column } allImports ]
    ]
