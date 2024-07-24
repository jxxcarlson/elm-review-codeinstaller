module Install.Internal.Import exposing
    ( Config(..)
    , Context
    , ImportedModule
    , finalEvaluation
    , importVisitor
    , init
    , moduleDefinitionVisitor
    )

import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module exposing (Module)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range as Range exposing (Range)
import Review.Fix as Fix
import Review.Rule as Rule exposing (Error)


type Config
    = Config
        { hostModuleName : List String
        , imports : List ImportedModule
        }


type alias ImportedModule =
    { moduleToImport : ModuleName
    , alias : Maybe String
    , exposedValues : Maybe (List String)
    }


type alias Context =
    { moduleName : ModuleName
    , moduleWasImported : Bool
    , lastNodeRange : Range
    , foundImports : List (List String)
    }


init : ModuleName -> Context
init moduleName =
    { moduleName = moduleName
    , moduleWasImported = False
    , lastNodeRange = Range.empty
    , foundImports = []
    }


importVisitor : Config -> Node Import -> Context -> Context
importVisitor (Config config) node context =
    if config.hostModuleName == context.moduleName then
        let
            currentModuleName : ModuleName
            currentModuleName =
                Node.value node |> .moduleName |> Node.value

            allModuleNames =
                List.map .moduleToImport config.imports

            foundImports =
                currentModuleName :: context.foundImports

            areAllImportsFound =
                List.all (\importedModuleName -> List.member importedModuleName foundImports) allModuleNames
        in
        if areAllImportsFound then
            { context | moduleWasImported = True, lastNodeRange = Node.range node }

        else
            { context | lastNodeRange = Node.range node, foundImports = foundImports }

    else
        context


moduleDefinitionVisitor : Node Module -> Context -> Context
moduleDefinitionVisitor def context =
    -- visit the module definition to set the module definition as the lastNodeRange in case the module has no imports yet
    { context | lastNodeRange = Node.range def }


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
