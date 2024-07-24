module Install.Internal.ReplaceFunction exposing
    ( Config(..)
    , declarationVisitor
    )

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (Range)
import Install.Library
import Review.Fix as Fix
import Review.Rule as Rule


type Config
    = Config
        { hostModuleName : ModuleName
        , functionName : String
        , functionImplementation : String
        }


declarationVisitor : Config -> Node Declaration -> List (Rule.Error {})
declarationVisitor (Config config) declaration =
    case Node.value declaration of
        FunctionDeclaration _ ->
            if
                (Install.Library.getDeclarationName declaration == config.functionName)
                    && (not <| Install.Library.isStringEqualToDeclaration config.functionImplementation declaration)
            then
                let
                    range : Range
                    range =
                        Node.range declaration
                in
                [ Rule.errorWithFix
                    { message = "Replace function \"" ++ config.functionName ++ "\""
                    , details = [ "" ]
                    }
                    range
                    [ Fix.replaceRangeBy range config.functionImplementation ]
                ]

            else
                []

        _ ->
            []
