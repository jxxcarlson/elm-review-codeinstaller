module Install.Function exposing (makeRule, init, Config, CustomError)

{-| Replace a function in a given module with a new implementation or
add that function definition if it is not present in the module.

    -- code for ReviewConfig.elm:
    rule =
        Install.Function.init
            "Frontend"
            "view"
            """view model =
       Html.text "This is a test\""""
            |> Install.Function.makeRule

Running this rule will insert or replace the function `view` in the module `Frontend` with the new implementation.

@docs makeRule, init, Config, CustomError

-}

import Dict
import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Case, Expression(..), Function, FunctionImplementation)
import Elm.Syntax.Module as Module
import Elm.Syntax.ModuleName as Module exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Range)
import Install.Infer as Infer
import Install.Library
import Install.Normalize as Normalize
import Review.Fix as Fix exposing (Fix)
import Review.ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (Error, Rule)


{-| Configuration for makeRule: add a clause to a case expression in a specified function in a specified module.
-}
type alias Config =
    { moduleName : String
    , functionName : String
    , functionImplementation : String
    , theFunctionNodeExpression : Maybe (Node Expression)
    , customErrorMessage : CustomError
    }


{-| Custom error message to be displayed when running `elm-review --fix` or `elm-review --fix-all`
-}
type CustomError
    = CustomError { message : String, details : List String }


{-| Initialize the configuration for the rule.
-}
init : String -> String -> String -> Config
init moduleName functionName functionImplementation =
    { moduleName = moduleName
    , functionName = functionName
    , functionImplementation = functionImplementation
    , theFunctionNodeExpression = Install.Library.maybeNodeExpressionFromString functionImplementation
    , customErrorMessage = CustomError { message = "Replace function \"" ++ functionName ++ "\" with new code.", details = [ "" ] }
    }


{-| Create a rule that replaces a function in a given module with a new implementation or
creates it if it is not present.
-}
makeRule : Config -> Rule
makeRule config =
    let
        visitor : Node Declaration -> Context -> ( List (Error {}), Context )
        visitor declaration context =
            declarationVisitor context config declaration
    in
    Rule.newModuleRuleSchemaUsingContextCreator "Install.Function" initialContext
        |> Rule.withDeclarationEnterVisitor visitor
        |> Rule.providesFixesForModuleRule
        |> Rule.fromModuleRuleSchema


type alias Context =
    { moduleName : ModuleName
    , lookupTable : ModuleNameLookupTable
    }


initialContext : Rule.ContextCreator () { moduleName : ModuleName, lookupTable : ModuleNameLookupTable }
initialContext =
    Rule.initContextCreator
        (\lookupTable moduleName () -> { lookupTable = lookupTable, moduleName = moduleName })
        |> Rule.withModuleNameLookupTable
        |> Rule.withModuleName


declarationVisitor : Context -> Config -> Node Declaration -> ( List (Rule.Error {}), Context )
declarationVisitor context config declaration =
    case Node.value declaration of
        FunctionDeclaration function ->
            let
                name : String
                name =
                    Node.value (Node.value function.declaration).name

                isInCorrectModule =
                    Install.Library.isInCorrectModule config.moduleName context

                resources =
                    { lookupTable = context.lookupTable, inferredConstants = ( Infer.empty, [] ) }

                isImplemented_ =
                    Maybe.map2 (Normalize.compare resources)
                        config.theFunctionNodeExpression
                        (Install.Library.getExpressionFromString config.functionImplementation)

                isImplemented =
                    --List.member isImplemented_ [ Just Normalize.ConfirmedEquality, Just Normalize.Unconfirmed ]
                    isImplemented_ == Just Normalize.ConfirmedEquality
            in
            if name == config.functionName && isInCorrectModule && isImplemented then
                visitFunction (Node.range declaration) config context

            else
                ( [], context )

        _ ->
            ( [], context )


visitFunction : Range -> Config -> Context -> ( List (Error {}), Context )
visitFunction range config context =
    ( [ errorWithFix_ config.functionName config.functionImplementation range ], context )


errorWithFix_ : String -> String -> Range -> Error {}
errorWithFix_ functionName functionImplemenation range =
    Rule.errorWithFix
        { message = "Replace function \"" ++ functionName ++ "\"", details = [ "" ] }
        range
        [ Fix.replaceRangeBy range functionImplemenation ]
