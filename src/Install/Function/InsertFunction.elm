module Install.Function.InsertFunction exposing (makeRule, config, Config, CustomError, withInsertAfter)

{-| Add a function in a given module if it is not present.

    -- code for ReviewConfig.elm:
    rule =
        Install.Function.InsertFunction.init
            "Frontend"
            "view"
            """view model =
            Html.text "This is a test\""""
            |> Install.Function.InsertFunction.makeRule

Running this rule will insert the function `view` in the module `Frontend` with the provided implementation.

The form of the rule is the same for nested modules:

    rule =
        Install.Function.InsertFunction.init
            "Foo.Bar"
            "earnInterest"
            "hoho model = { model | interest = 1.03 * model.interest }"
            |> Install.Function.InsertFunction.makeRule

@docs makeRule, init, Config, CustomError, withInsertAfter

-}

import Elm.Syntax.Declaration exposing (Declaration)
import Elm.Syntax.Expression exposing (Expression)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range as Range exposing (Range)
import Install.Library
import Review.Fix as Fix
import Review.ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (Error, Rule)


{-| Configuration for makeRule: add a function in a specified module if it does not already exist.
-}
type Config
    = Config
        { moduleName : String
        , functionName : String
        , functionImplementation : String
        , theFunctionNodeExpression : Maybe (Node Expression)
        , customErrorMessage : CustomError
        , insertAt : InsertAt
        }


{-| Custom error message to be displayed when running `elm-review --fix` or `elm-review --fix-all`
-}
type CustomError
    = CustomError { message : String, details : List String }


type InsertAt
    = After String
    | AtEnd


{-| Add the function after a specified declaration. Just give the name of a function, type, type alias or port and the function will be added after that declaration. Only work if the function is being added and not replaced.
-}
withInsertAfter : String -> Config -> Config
withInsertAfter previousDeclaration (Config config_) =
    Config { config_ | insertAt = After previousDeclaration }


{-| Initialize the configuration for the rule.
-}
config : String -> String -> String -> Config
config moduleNaeme functionName functionImplementation =
    Config
        { moduleName = moduleNaeme
        , functionName = functionName
        , functionImplementation = functionImplementation
        , theFunctionNodeExpression = Install.Library.maybeNodeExpressionFromString { moduleName = String.split "." moduleNaeme } functionImplementation
        , customErrorMessage = CustomError { message = "Add function \"" ++ functionName ++ "\".", details = [ "" ] }
        , insertAt = AtEnd
        }


{-| Create a rule that adds a function in a given module if it is not present.
-}
makeRule : Config -> Rule
makeRule config_ =
    let
        visitor : Node Declaration -> Context -> ( List (Error {}), Context )
        visitor declaration context =
            declarationVisitor context config_ declaration
    in
    Rule.newModuleRuleSchemaUsingContextCreator "Install.Function.InsertFunction" initialContext
        |> Rule.withDeclarationEnterVisitor visitor
        |> Rule.withFinalModuleEvaluation (finalEvaluation config_)
        |> Rule.providesFixesForModuleRule
        |> Rule.fromModuleRuleSchema


type alias Context =
    { moduleName : ModuleName
    , lookupTable : ModuleNameLookupTable
    , lastDeclarationRange : Range
    , appliedFix : Bool
    }


initialContext : Rule.ContextCreator () Context
initialContext =
    Rule.initContextCreator
        (\lookupTable moduleName () -> { lookupTable = lookupTable, moduleName = moduleName, lastDeclarationRange = Range.empty, appliedFix = False })
        |> Rule.withModuleNameLookupTable
        |> Rule.withModuleName


declarationVisitor : Context -> Config -> Node Declaration -> ( List (Rule.Error {}), Context )
declarationVisitor context (Config config_) declaration =
    let
        declarationName =
            Install.Library.getDeclarationName declaration

        contextWithLastDeclarationRange =
            case config_.insertAt of
                After previousDeclaration ->
                    if Install.Library.getDeclarationName declaration == previousDeclaration then
                        { context | lastDeclarationRange = Node.range declaration }

                    else
                        context

                AtEnd ->
                    { context | lastDeclarationRange = Node.range declaration }
    in
    if declarationName == config_.functionName then
        ( [], { context | appliedFix = True } )

    else
        ( [], contextWithLastDeclarationRange )


finalEvaluation : Config -> Context -> List (Rule.Error {})
finalEvaluation (Config config_) context =
    if not context.appliedFix && Install.Library.isInCorrectModule config_.moduleName context then
        addFunction { range = context.lastDeclarationRange, functionName = config_.functionName, functionImplementation = config_.functionImplementation }

    else
        []


type alias FixConfig =
    { range : Range
    , functionName : String
    , functionImplementation : String
    }


addFunction : FixConfig -> List (Error {})
addFunction fixConfig =
    [ Rule.errorWithFix
        { message = "Add function \"" ++ fixConfig.functionName ++ "\"", details = [ "" ] }
        fixConfig.range
        [ Fix.insertAt { row = fixConfig.range.end.row + 1, column = 0 } fixConfig.functionImplementation ]
    ]
