module Install.Import exposing (..)

import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range as Range exposing (Range)
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error, Rule)
import Set exposing (Set)


type alias Config =
    { hostModuleName : List String
    , importedModuleName : List String
    , customErrorMessage : CustomError
    , importedModuleAlias : Maybe String
    , exposedValues : Maybe (List String)
    }


{-| Custom error message to be displayed when running `elm-review --fix` or `elm-review --fix-all`
-}
type CustomError
    = CustomError { message : String, details : List String }


{-| Initialize the configuration for the rule.
-}
init : String -> String -> Config
init hostModuleName_ importedModuleName_ =
    { hostModuleName = String.split "." hostModuleName_
    , importedModuleName = String.split "." importedModuleName_
    , customErrorMessage = CustomError { message = "Install module " ++ importedModuleName_ ++ " in " ++ importedModuleName_, details = [ "" ] }
    , importedModuleAlias = Nothing
    , exposedValues = Nothing
    }


withAlias : String -> Config -> Config
withAlias alias config =
    { config | importedModuleAlias = Just alias }


withExposedValues : List String -> Config -> Config
withExposedValues exposedValues config =
    { config | exposedValues = Just exposedValues }


{-| Create a rule that adds an import for a given module in a given module. For example:

     Install.Import.makeRule "Frontend" "Foo.Bar" "add: import module Foo."

-}
makeRule : Config -> Rule
makeRule config =
    Rule.newModuleRuleSchemaUsingContextCreator "Install.Import" initialContext
        |> Rule.withImportVisitor (importVisitor config)
        |> Rule.withFinalModuleEvaluation (finalEvaluation config)
        |> Rule.providesFixesForModuleRule
        |> Rule.fromModuleRuleSchema


type alias Context =
    { moduleName : ModuleName
    , moduleWasImported : Bool
    , lastNodeRange : Range
    }


initialContext : Rule.ContextCreator () Context
initialContext =
    Rule.initContextCreator
        (\moduleName () -> { moduleName = moduleName, moduleWasImported = False, lastNodeRange = Range.empty })
        |> Rule.withModuleName


importVisitor : Config -> Node Import -> Context -> ( List (Error {}), Context )
importVisitor config node context =
    case Node.value node |> .moduleName |> Node.value of
        currentModuleName ->
            if currentModuleName == config.importedModuleName && config.hostModuleName == context.moduleName then
                ( [], { context | moduleWasImported = True, lastNodeRange = Node.range node } )

            else
                ( [], { context | lastNodeRange = Node.range node } )


finalEvaluation : Config -> Context -> List (Rule.Error {})
finalEvaluation config context =
    if context.moduleWasImported == False && config.hostModuleName == context.moduleName then
        fixError config context

    else
        []


fixError : Config -> Context -> List (Error {})
fixError config context =
    let
        importText =
            "import "
                ++ String.join "." config.importedModuleName
                ++ " "
                |> addAlias config.importedModuleAlias
                |> addExposing config.exposedValues
                |> Debug.log "importText"

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
    in
    [ Rule.errorWithFix
        { message = "moduleToImport: \"" ++ String.join "." config.importedModuleName ++ "\"", details = [ "" ] }
        context.lastNodeRange
        [ Fix.insertAt { row = context.lastNodeRange.end.row + 1, column = context.lastNodeRange.end.column } importText ]
    ]
