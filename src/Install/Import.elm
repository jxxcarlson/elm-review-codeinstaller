module Install.Import exposing (init, initSimple, makeRule)

{-| Add import statements to a given module.
For example, to add `import Foo.Bar` to the `Frontend` module, you can use the following configuration:

    Install.Import.init "Frontend"
        [ { moduleToImport = "Foo.Bar", alias_ = Nothing, exposedValues = Nothing } ]
        |> Install.Import.makeRule

To add the statement `import Foo.Bar as FB exposing (a, b, c)` to the `Frontend` module, do this:

    Install.Import.init "Frontend" [ { moduleToImport = "Foo.Bar", alias_ = Just "FB", exposedValues = Just [ "a", "b", "c" ] } ]
        |> Install.Import.makeRule

There is a short cut for importing modules with no alias or exposed values:

    Install.Import.initSimple "Frontend" [ "Foo.Bar", "Baz.Qux" ]
        |> Install.Import.makeRule

@docs init, initSimple, makeRule

-}

import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module exposing (Module)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range as Range exposing (Range)
import Review.Fix as Fix
import Review.Rule as Rule exposing (Error, Rule)


{-|

    Configuration for  the rule.

-}
type Config
    = Config
        { hostModuleName : List String
        , imports : List ImportedModule
        , customErrorMessage : CustomError
        }


type alias ImportedModule =
    { moduleToImport : ModuleName
    , alias_ : Maybe String
    , exposedValues : Maybe (List String)
    }


{-| Custom error message to be displayed when running `elm-review --fix` or `elm-review --fix-all`
-}
type CustomError
    = CustomError { message : String, details : List String }


{-| Initialize the configuration for the rule.
-}
init : String -> List { moduleToImport : String, alias_ : Maybe String, exposedValues : Maybe (List String) } -> Config
init hostModuleName_ imports =
    Config
        { hostModuleName = String.split "." hostModuleName_
        , imports = List.map (\{ moduleToImport, alias_, exposedValues } -> { moduleToImport = String.split "." moduleToImport, alias_ = alias_, exposedValues = exposedValues }) imports
        , customErrorMessage = CustomError { message = "Install imports in module " ++ hostModuleName_, details = [ "" ] }
        }


{-| Initialize the configuration for the rule.
-}
initSimple : String -> List String -> Config
initSimple hostModuleName_ imports =
    Config
        { hostModuleName = String.split "." hostModuleName_
        , imports = List.map (\moduleToImport -> { moduleToImport = String.split "." moduleToImport, alias_ = Nothing, exposedValues = Nothing }) imports
        , customErrorMessage = CustomError { message = "Install imports in module " ++ hostModuleName_, details = [ "" ] }
        }


{-| Create a rule that adds a list of imports for given modules in a given module.
See above for examples.
-}
makeRule : Config -> Rule
makeRule config =
    Rule.newModuleRuleSchemaUsingContextCreator "Install.Import" initialContext
        |> Rule.withImportVisitor (importVisitor config)
        |> Rule.withModuleDefinitionVisitor moduleDefinitionVisitor
        |> Rule.withFinalModuleEvaluation (finalEvaluation config)
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
importVisitor (Config config) node context =
    case Node.value node |> .moduleName |> Node.value of
        currentModuleName ->
            let
                allModuleNames =
                    List.map .moduleToImport config.imports

                foundImports =
                    context.foundImports ++ [ currentModuleName ]

                areAllImportsFound =
                    List.all (\importedModuleName -> List.member importedModuleName foundImports) allModuleNames
            in
            if areAllImportsFound && config.hostModuleName == context.moduleName then
                ( [], { context | moduleWasImported = True, lastNodeRange = Node.range node } )

            else
                ( [], { context | lastNodeRange = Node.range node, foundImports = foundImports } )


moduleDefinitionVisitor : Node Module -> Context -> ( List (Error {}), Context )
moduleDefinitionVisitor def context =
    -- visit the module definition to set the module definition as the lastNodeRange in case the module has no imports yet
    ( [], { context | lastNodeRange = Node.range def } )


finalEvaluation : Config -> Context -> List (Rule.Error {})
finalEvaluation (Config config) context =
    if context.moduleWasImported == False && config.hostModuleName == context.moduleName then
        fixError config.imports context

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
            List.map (\{ moduleToImport, alias_, exposedValues } -> importText moduleToImport alias_ exposedValues) uniqueImports
                |> String.join "\n"

        addAlias : Maybe String -> String -> String
        addAlias mAlias str =
            case mAlias of
                Nothing ->
                    str

                Just alias_ ->
                    str ++ " as " ++ alias_

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
