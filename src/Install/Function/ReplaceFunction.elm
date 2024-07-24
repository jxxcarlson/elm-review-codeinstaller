module Install.Function.ReplaceFunction exposing (makeRule, config, Config, CustomError)

{-| Replace a function in a given module with a new implementation.

    -- code for ReviewConfig.elm:
    rule =
        Install.Function.InsertFunction.config
            "Frontend"
            "view"
            """view model =
            Html.text "This is a test\""""
            |> Install.Function.InsertFunction.makeRule

Running this rule will replace the function `view` in the module `Frontend` with the provided implementation.

The form of the rule is the same for nested modules:

    rule =
        Install.Function.ReplaceFunction.config
            "Foo.Bar"
            "earnInterest"
            "hoho model = { model | interest = 1.03 * model.interest }"
            |> Install.Function.ReplaceFunction.makeRule

@docs makeRule, config, Config, CustomError

-}

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression, Function)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (Range)
import Install.Library
import Review.Fix as Fix
import Review.ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (Error, Rule)


{-| Configuration for rule: replace a function in a specified module with a new implementation.
-}
type Config
    = Config
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
config : String -> String -> String -> Config
config moduleName functionName functionImplementation =
    Config
        { moduleName = moduleName
        , functionName = functionName
        , functionImplementation = functionImplementation
        , theFunctionNodeExpression = Install.Library.maybeNodeExpressionFromString { moduleName = String.split "." moduleName } functionImplementation
        , customErrorMessage = CustomError { message = "Replace function \"" ++ functionName ++ "\" with new code.", details = [ "" ] }
        }


{-| Create a rule that replaces a function in a given module with a new implementation.
-}
makeRule : Config -> Rule
makeRule config_ =
    let
        visitor : Node Declaration -> Context -> ( List (Error {}), Context )
        visitor declaration context =
            declarationVisitor context config_ declaration
    in
    Rule.newModuleRuleSchemaUsingContextCreator "Install.Function.ReplaceFunction" initialContext
        |> Rule.withDeclarationEnterVisitor visitor
        |> Rule.providesFixesForModuleRule
        |> Rule.fromModuleRuleSchema


type alias Context =
    { moduleName : ModuleName
    , lookupTable : ModuleNameLookupTable
    }


initialContext : Rule.ContextCreator () Context
initialContext =
    Rule.initContextCreator
        (\lookupTable moduleName () -> { lookupTable = lookupTable, moduleName = moduleName })
        |> Rule.withModuleNameLookupTable
        |> Rule.withModuleName


declarationVisitor : Context -> Config -> Node Declaration -> ( List (Rule.Error {}), Context )
declarationVisitor context (Config config_) declaration =
    case Node.value declaration of
        FunctionDeclaration function ->
            let
                name : String
                name =
                    Install.Library.getDeclarationName declaration

                isInCorrectModule =
                    Install.Library.isInCorrectModule config_.moduleName context

                isInCorrectFunction =
                    isInCorrectModule && name == config_.functionName

                isNotImplemented : Function -> { a | functionImplementation : String } -> Bool
                isNotImplemented f confg =
                    isInCorrectFunction && (Install.Library.isStringEqualToDeclaration confg.functionImplementation declaration |> not)
            in
            if isNotImplemented function config_ then
                replaceFunction { range = Node.range declaration, functionName = config_.functionName, functionImplementation = config_.functionImplementation } context

            else
                ( [], context )

        _ ->
            ( [], context )


replaceFunction : FixConfig -> Context -> ( List (Error {}), Context )
replaceFunction fixConfig context =
    ( [ Rule.errorWithFix
            { message = "Replace function \"" ++ fixConfig.functionName ++ "\"", details = [ "" ] }
            fixConfig.range
            [ Fix.replaceRangeBy fixConfig.range fixConfig.functionImplementation ]
      ]
    , context
    )


type alias FixConfig =
    { range : Range
    , functionName : String
    , functionImplementation : String
    }
