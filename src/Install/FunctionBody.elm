module Install.FunctionBody exposing (..)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Case, Expression(..), Function, FunctionImplementation)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Pattern exposing (Pattern(..))
import Elm.Syntax.Range exposing (Range)
import List.Extra
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error, Rule)
import Set exposing (Set)
import String.Extra


{-| Configuration for makeRule: add a clause to a case expression in a specified function in a specified module.
-}
type Config
    = Config
        { moduleName : String
        , functionName : String
        , functionArgs : List String
        , functionBody : String
        , customErrorMessage : CustomError
        }


{-| Custom error message to be displayed when running `elm-review --fix` or `elm-review --fix-all`
-}
type CustomError
    = CustomError { message : String, details : List String }


init : String -> String -> List String -> String -> Config
init moduleName functionName functionArgs functionBody =
    Config
        { moduleName = moduleName
        , functionName = functionName
        , functionArgs = functionArgs
        , functionBody = functionBody
        , customErrorMessage = CustomError { message = "Replace function body for function " ++ clause, details = [ "" ] }
        }
