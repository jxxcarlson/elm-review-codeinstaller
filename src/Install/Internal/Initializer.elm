module Install.Internal.Initializer exposing
    ( Config(..)
    , declarationVisitor
    )

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression(..), Function, FunctionImplementation)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Range)
import Install.Library
import List.Extra
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error)
import Set
import Set.Extra


type Config
    = Config
        { hostModuleName : ModuleName
        , functionName : String
        , data : List { field : String, value : String }
        }


declarationVisitor : Config -> Node Declaration -> List (Rule.Error {})
declarationVisitor (Config { data, functionName }) (Node _ declaration) =
    case declaration of
        FunctionDeclaration function ->
            let
                name : String
                name =
                    Node.value (Node.value function.declaration).name
            in
            if name == functionName then
                visitFunction data function

            else
                []

        _ ->
            []


visitFunction : List { field : String, value : String } -> Function -> List (Rule.Error {})
visitFunction data function =
    let
        declaration : FunctionImplementation
        declaration =
            Node.value function.declaration

        ( fieldNames, lastRange ) =
            getFieldNamesAndLastRange (Node.value declaration.expression)

        existingFields =
            Set.fromList fieldNames

        newFields =
            List.map .field data |> Set.fromList
    in
    if not <| Set.Extra.isSubsetOf existingFields newFields then
        [ errorWithFix data function.declaration (Just lastRange) ]

    else
        []


errorWithFix : List { field : String, value : String } -> Node a -> Maybe Range -> Error {}
errorWithFix data node errorRange =
    Rule.errorWithFix
        { message = "Add fields to the model"
        , details =
            [ ""
            ]
        }
        (Node.range node)
        (case errorRange of
            Just range ->
                let
                    insertionPoint =
                        { row = range.end.row, column = range.end.column }
                in
                [ addMissingCases insertionPoint data ]

            Nothing ->
                []
        )


addMissingCases : { row : Int, column : Int } -> List { field : String, value : String } -> Fix
addMissingCases insertionPoint data =
    let
        insertion =
            ", " ++ (List.map (\{ field, value } -> field ++ " = " ++ value) data |> String.join ", ")
    in
    Fix.insertAt
        { row = insertionPoint.row
        , column = insertionPoint.column
        }
        insertion


getFieldNamesAndLastRange : Expression -> ( List String, Range )
getFieldNamesAndLastRange expr =
    case expr of
        TupledExpression expressions ->
            let
                lastRange =
                    case expressions |> List.head |> Maybe.map Node.value of
                        Just expression ->
                            Install.Library.lastRange expression

                        Nothing ->
                            Elm.Syntax.Range.empty

                fieldNames : List String
                fieldNames =
                    case List.head expressions of
                        Just (Node _ recordExpr) ->
                            Install.Library.fieldNames recordExpr

                        Nothing ->
                            []
            in
            ( fieldNames, lastRange )

        LetExpression { expression } ->
            getFieldNamesAndLastRange (Node.value expression)

        Application children ->
            children
                |> List.Extra.find
                    (\child ->
                        case Node.value child of
                            TupledExpression _ ->
                                True

                            _ ->
                                False
                    )
                |> Maybe.map Node.value
                |> Maybe.withDefault (TupledExpression [])
                |> getFieldNamesAndLastRange

        _ ->
            ( [], Elm.Syntax.Range.empty )
