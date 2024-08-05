module Install.Internal.InitializerCmd exposing
    ( Config(..)
    , declarationVisitor
    )

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression(..), Function, FunctionImplementation)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Range)
import Install.Library
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error)


type Config
    = Config
        { hostModuleName : ModuleName
        , functionName : String
        , cmds : List String
        }


declarationVisitor : Config -> Node Declaration -> List (Rule.Error {})
declarationVisitor (Config config) (Node _ declaration) =
    case declaration of
        FunctionDeclaration function ->
            let
                name : String
                name =
                    Node.value (Node.value function.declaration).name
            in
            if name == config.functionName then
                visitCmd config.cmds function

            else
                []

        _ ->
            []


visitCmd : List String -> Function -> List (Rule.Error {})
visitCmd cmds function =
    let
        declaration : FunctionImplementation
        declaration =
            Node.value function.declaration

        ( val, range ) =
            case declaration.expression |> Node.value of
                TupledExpression expressions ->
                    case expressions of
                        [ _, oldCmds ] ->
                            let
                                range_ =
                                    Node.range oldCmds
                            in
                            ( Just oldCmds, range_ )

                        _ ->
                            ( Nothing, Elm.Syntax.Range.empty )

                _ ->
                    ( Nothing, Elm.Syntax.Range.empty )

        stringifiedCmds =
            Maybe.map Install.Library.expressionToString val
    in
    if stringifiedCmds == Just "Cmd.none" then
        [ errorWithFix cmds function.declaration (Just range) ]

    else
        []


errorWithFix : List String -> Node a -> Maybe Range -> Error {}
errorWithFix cmds node errorRange =
    Rule.errorWithFix
        { message = "Add cmds " ++ String.join ", " cmds ++ " to the model"
        , details =
            [ ""
            ]
        }
        (Node.range node)
        (case errorRange of
            Just range ->
                [ replaceCmds range cmds ]

            Nothing ->
                []
        )



--  Cmd.none -> (FunctionOrValue ["Cmd"] "none")
-- hohoho -> (FunctionOrValue [] "hohoho")


replaceCmds : Range -> List String -> Fix
replaceCmds rangeToReplace cmds =
    let
        replacement =
            "Cmd.batch [ " ++ String.join ", " cmds ++ " ]"
    in
    Fix.replaceRangeBy rangeToReplace replacement
