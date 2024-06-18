module Install.Function exposing (makeRule, init, Config, CustomError, withInsertAfter)

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
The form of the rule is the same for nested modules:

    rule =
        Install.Function.init
            "Foo.Bar"
            "earnInterest"
            "hoho model = { model | interest = 1.03 * model.interest }"
            |> Install.Function.makeRule

@docs makeRule, init, Config, CustomError, withInsertAfter

-}

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression, Function)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range as Range exposing (Range)
import Install.Infer as Infer
import Install.Library
import Install.Normalize as Normalize
import Review.Fix as Fix
import Review.ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (Error, Rule)


{-| Configuration for makeRule: add (or replace if function already exists) a function in a specified module.
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
withInsertAfter previousDeclaration (Config config) =
    Config { config | insertAt = After previousDeclaration }


{-| Initialize the configuration for the rule.
-}
init : String -> String -> String -> Config
init moduleNaeme functionName functionImplementation =
    Config
        { moduleName = moduleNaeme
        , functionName = functionName
        , functionImplementation = functionImplementation
        , theFunctionNodeExpression = Install.Library.maybeNodeExpressionFromString { moduleName = String.split "." moduleNaeme } functionImplementation
        , customErrorMessage = CustomError { message = "Replace function \"" ++ functionName ++ "\" with new code.", details = [ "" ] }
        , insertAt = AtEnd
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
        |> Rule.withFinalModuleEvaluation (finalEvaluation config)
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
declarationVisitor context (Config config) declaration =
    let
        contextWithLastDeclarationRange =
            case config.insertAt of
                After previousDeclaration ->
                    if getDeclarationName declaration == previousDeclaration then
                        { context | lastDeclarationRange = Node.range declaration }

                    else
                        context

                AtEnd ->
                    { context | lastDeclarationRange = Node.range declaration }
    in
    case Node.value declaration of
        FunctionDeclaration function ->
            let
                name : String
                name =
                    getDeclarationName declaration

                isInCorrectModule =
                    Install.Library.isInCorrectModule (config.moduleName |> Debug.log "MODULE_NAME") context

                resources =
                    { lookupTable = context.lookupTable, inferredConstants = ( Infer.empty, [] ) }

                -- isNotImplemented returns True if the values of the current function expression and the replacement expression are different
                isNotImplemented : Function -> { a | functionImplementation : String } -> Bool
                isNotImplemented f confg =
                    Maybe.map2 (Normalize.compare resources)
                        (f.declaration |> Node.value |> .expression |> Just)
                        (Install.Library.getExpressionFromString context confg.functionImplementation)
                        == Just Normalize.ConfirmedEquality
                        |> not
            in
            if name == config.functionName && isInCorrectModule && isNotImplemented function config then
                replaceFunction { range = Node.range declaration, functionName = config.functionName, functionImplementation = config.functionImplementation } context

            else
                ( [], contextWithLastDeclarationRange )

        _ ->
            ( [], contextWithLastDeclarationRange )


type alias FixConfig =
    { range : Range
    , functionName : String
    , functionImplementation : String
    }


finalEvaluation : Config -> Context -> List (Rule.Error {})
finalEvaluation (Config config) context =
    if not context.appliedFix && Install.Library.isInCorrectModule config.moduleName context then
        addFunction { range = context.lastDeclarationRange, functionName = config.functionName, functionImplementation = config.functionImplementation }

    else
        []


replaceFunction : FixConfig -> Context -> ( List (Error {}), Context )
replaceFunction fixConfig context =
    ( [ Rule.errorWithFix
            { message = "Replace function \"" ++ fixConfig.functionName ++ "\"", details = [ "" ] }
            fixConfig.range
            [ Fix.replaceRangeBy fixConfig.range fixConfig.functionImplementation ]
      ]
    , { context | appliedFix = True }
    )


addFunction : FixConfig -> List (Error {})
addFunction fixConfig =
    [ Rule.errorWithFix
        { message = "Add function \"" ++ fixConfig.functionName ++ "\"", details = [ "" ] }
        fixConfig.range
        [ Fix.insertAt { row = fixConfig.range.end.row + 1, column = 0 } fixConfig.functionImplementation ]
    ]


getDeclarationName : Node Declaration -> String
getDeclarationName declaration =
    let
        getName declaration_ =
            declaration_ |> .name >> Node.value
    in
    case Node.value declaration of
        FunctionDeclaration function ->
            getName (Node.value function.declaration)

        AliasDeclaration alias_ ->
            getName alias_

        CustomTypeDeclaration customType ->
            getName customType

        PortDeclaration port_ ->
            getName port_

        _ ->
            ""
