module Install.Internal.InsertFunction exposing
    ( Config(..)
    , Context
    , InsertAt(..)
    , declarationVisitor
    , finalEvaluation
    , init
    )

import Elm.Syntax.Declaration exposing (Declaration)
import Elm.Syntax.Expression exposing (Expression)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range as Range exposing (Range)
import Install.Library
import Review.Fix as Fix
import Review.Rule as Rule exposing (Error)


type Config
    = Config
        { hostModuleName : ModuleName
        , functionName : String
        , functionImplementation : String
        , theFunctionNodeExpression : Maybe (Node Expression)
        , insertAt : InsertAt
        }


type InsertAt
    = After String
    | AtEnd


type alias Context =
    { lastDeclarationRange : Range
    , appliedFix : Bool
    }


init : Context
init =
    { lastDeclarationRange = Range.empty
    , appliedFix = False
    }


declarationVisitor : Config -> Node Declaration -> Context -> Context
declarationVisitor (Config config) declaration context =
    let
        declarationName =
            Install.Library.getDeclarationName declaration
    in
    if declarationName == config.functionName then
        { context | appliedFix = True }

    else
        case config.insertAt of
            After previousDeclaration ->
                if Install.Library.getDeclarationName declaration == previousDeclaration then
                    { context | lastDeclarationRange = Node.range declaration }

                else
                    context

            AtEnd ->
                { context | lastDeclarationRange = Node.range declaration }


finalEvaluation : Config -> Context -> List (Rule.Error {})
finalEvaluation (Config config) context =
    if not context.appliedFix then
        addFunction { range = context.lastDeclarationRange, functionName = config.functionName, functionImplementation = config.functionImplementation }

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
