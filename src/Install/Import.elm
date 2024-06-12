module Install.Import exposing (..)

import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range as Range exposing (Range)
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error, Rule)
import Set exposing (Set)


{-| Custom error message to be displayed when running `elm-review --fix` or `elm-review --fix-all`
-}
type CustomError
    = CustomError { message : String, details : List String }


{-| Create a rule that adds an import for a given module in a given module. For example:

     Install.Import.makeRule "Frontend" "Foo.Bar" "add: import module Foo."

-}
makeRule : String -> String -> String -> Rule
makeRule hostModuleName importedModuleName customErrorMessage =
    let
        hostModuleNameList =
            String.split "." hostModuleName

        importedModuleNameList =
            String.split "." importedModuleName
    in
    Rule.newModuleRuleSchemaUsingContextCreator "Install.Import" initialContext
        |> Rule.withImportVisitor (importVisitor hostModuleNameList importedModuleNameList)
        |> Rule.withFinalModuleEvaluation (finalEvaluation hostModuleNameList importedModuleNameList)
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


importVisitor : List String -> List String -> Node Import -> Context -> ( List (Error {}), Context )
importVisitor hostModuleNameList importedModuleNameList node context =
    case Node.value node |> .moduleName |> Node.value of
        currentModuleName ->
            if currentModuleName == importedModuleNameList && hostModuleNameList == context.moduleName then
                ( [], { context | moduleWasImported = True, lastNodeRange = Node.range node } )

            else
                ( [], { context | lastNodeRange = Node.range node } )


finalEvaluation : List String -> List String -> Context -> List (Rule.Error {})
finalEvaluation hostModuleNameList moduleToImport context =
    let
        _ =
            Debug.log "CONTEXT" context
    in
    if context.moduleWasImported == False && hostModuleNameList == context.moduleName then
        fixError moduleToImport context

    else
        []


fixError : List String -> Context -> List (Error {})
fixError moduleToImport context =
    [ Rule.errorWithFix
        { message = "moduleToImport: \"" ++ String.join "." moduleToImport ++ "\"", details = [ "" ] }
        context.lastNodeRange
        [ Fix.insertAt { row = context.lastNodeRange.end.row + 1, column = context.lastNodeRange.end.column } ("import " ++ String.join "." moduleToImport) ]
    ]
