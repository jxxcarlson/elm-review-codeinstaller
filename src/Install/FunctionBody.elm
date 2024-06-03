module Install.FunctionBody exposing (..)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Case, Expression(..), Function, FunctionImplementation)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Range)
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error, Rule)
import Set exposing (Set)


{-| Configuration for makeRule: add a clause to a case expression in a specified function in a specified module.
-}
type Config
    = Config
        { moduleName : String
        , functionName : String
        , functionImplementation : String
        , customErrorMessage : CustomError
        }


{-| Custom error message to be displayed when running `elm-review --fix` or `elm-review --fix-all`
-}
type CustomError
    = CustomError { message : String, details : List String }


init : String -> String -> String -> Config
init moduleName functionName functionImplementation =
    Config
        { moduleName = moduleName
        , functionName = functionName
        , functionImplementation = functionImplementation
        , customErrorMessage = CustomError { message = "Replace function \"" ++ functionName ++ "\" with new code.", details = [ "" ] }
        }


type alias Ignored =
    Set String


makeRule : Config -> Rule
makeRule (Config config) =
    let
        visitor : Node Declaration -> Context -> ( List (Error {}), Context )
        visitor declaration context =
            declarationVisitor declaration config.moduleName config.functionName config.functionImplementation context config.customErrorMessage
    in
    Rule.newModuleRuleSchemaUsingContextCreator "Install.FunctionBody" contextCreator
        |> Rule.withDeclarationEnterVisitor visitor
        |> Rule.providesFixesForModuleRule
        |> Rule.fromModuleRuleSchema


type alias Context =
    { moduleName : ModuleName
    }


contextCreator : Rule.ContextCreator () { moduleName : ModuleName }
contextCreator =
    Rule.initContextCreator
        (\moduleName () ->
            { moduleName = moduleName

            -- ...other fields
            }
        )
        |> Rule.withModuleName


declarationVisitor : Node Declaration -> String -> String -> String -> Context -> CustomError -> ( List (Rule.Error {}), Context )
declarationVisitor node moduleName functionName functionImplementation context customError =
    case Node.value node of
        FunctionDeclaration function ->
            let
                name : String
                name =
                    Node.value (Node.value function.declaration).name

                isInCorrectModule =
                    moduleName == (context.moduleName |> String.join "")
            in
            if name == functionName && isInCorrectModule then
                visitFunction (Node.range node) functionName functionImplementation context

            else
                ( [], context )

        _ ->
            ( [], context )


visitFunction : Range -> String -> String -> Context -> ( List (Error {}), Context )
visitFunction range functionName functionImplemenation context =
    ( [ errorWithFix_ functionName functionImplemenation range ], context )


errorWithFix_ : String -> String -> Range -> Error {}
errorWithFix_ functionName functionImplemenation range =
    Rule.errorWithFix
        { message = "Replace function \"" ++ functionName ++ "\"", details = [ "" ] }
        range
        [ Fix.replaceRangeBy range functionImplemenation ]
