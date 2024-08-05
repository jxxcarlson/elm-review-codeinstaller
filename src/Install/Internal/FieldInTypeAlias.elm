module Install.Internal.FieldInTypeAlias exposing (Config(..), declarationVisitor, getFieldName)

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (Range)
import Elm.Syntax.TypeAnnotation as TypeAnnotation
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error)
import Set exposing (Set)
import Set.Extra


type Config
    = Config
        { hostModuleName : ModuleName
        , typeName : String
        , fieldDefinitions : List String
        , fieldNames : Set String
        }


declarationVisitor : Config -> Node Declaration -> List (Error {})
declarationVisitor (Config { typeName, fieldNames, fieldDefinitions }) node =
    case Node.value node of
        Declaration.AliasDeclaration type_ ->
            let
                fieldsOfNode : Node Declaration -> List String
                fieldsOfNode node_ =
                    case Node.value node_ of
                        Declaration.AliasDeclaration typeAlias ->
                            case typeAlias.typeAnnotation |> Node.value of
                                TypeAnnotation.Record fields ->
                                    fields
                                        |> List.map (Node.value >> Tuple.first >> Node.value)

                                _ ->
                                    []

                        _ ->
                            []

                shouldFix : Node Declaration -> Bool
                shouldFix node_ =
                    let
                        fieldsOfNode_ =
                            fieldsOfNode node_
                    in
                    not <| Set.Extra.isSubsetOf (Set.fromList fieldsOfNode_) fieldNames
            in
            if Node.value type_.name == typeName && shouldFix node then
                let
                    fieldsToAdd : Set String
                    fieldsToAdd =
                        Set.diff fieldNames (Set.fromList <| fieldsOfNode node)

                    getFieldCode field =
                        "    , " ++ field ++ "\n"

                    closeRecord =
                        "    }"

                    -- filter out the fields that are already in the type alias
                    newFields : List String
                    newFields =
                        fieldDefinitions
                            |> List.filter (\field -> Set.member (getFieldName field) fieldsToAdd)

                    fieldsCode =
                        newFields
                            |> List.map getFieldCode
                            |> String.concat
                            |> (\fields -> fields ++ closeRecord)
                in
                [ errorWithFix typeName fieldsToAdd fieldsCode node (Just <| Node.range node) ]

            else
                []

        _ ->
            []


errorWithFix : String -> Set String -> String -> Node a -> Maybe Range -> Error {}
errorWithFix typeName_ fieldsName fieldCode node errorRange =
    let
        fieldsNameList =
            Set.toList fieldsName

        fieldName =
            case fieldsNameList of
                [ field ] ->
                    field

                _ ->
                    "fields " ++ String.join ", " fieldsNameList
    in
    Rule.errorWithFix
        { message = "Add " ++ fieldName ++ " to " ++ typeName_
        , details =
            [ "" ]
        }
        (Node.range node)
        (case errorRange of
            Just range ->
                [ fixMissingField range.end fieldCode ]

            Nothing ->
                []
        )


fixMissingField : { row : Int, column : Int } -> String -> Fix
fixMissingField { row, column } fieldCode =
    let
        range =
            { start = { row = row, column = 0 }, end = { row = row, column = column } }
    in
    Fix.replaceRangeBy range fieldCode


getFieldName : String -> String
getFieldName field =
    field
        |> String.split ":"
        |> List.head
        |> Maybe.withDefault ""
        |> String.trim
