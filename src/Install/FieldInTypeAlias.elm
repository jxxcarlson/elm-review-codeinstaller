module Install.FieldInTypeAlias exposing (makeRule)

{-| Add a field to specified type alias
in a specified module. For example, if you put the code below in your
`ReviewConfig.elm` file, running `elm-review` will add the field
`quot: String` to the type alias `FrontendModel` in the `Types` module.

    -- code for ReviewConfig.elm:
    Install.FieldInTypeAlias.makeRule "Types" "FrontendModel" "quot: String"

Thus we will have

    type alias FrontendModel =
        { counter : Int
        , clientId : String
        , quot : String
        }

@docs makeRule

-}

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (Range)
import Elm.Syntax.TypeAnnotation as TypeAnnotation
import Install.Library
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error, Rule)
import Set exposing (Set)
import Set.Extra


{-| Create a rule that adds a field to a type alias in a specified module. Example usage:

    module Types exposing (FrontendModel)

    type alias FrontendModel =
        { counter : Int
        , clientId : String
        }

After running the rule with the following code:

    Install.FieldInTypeAlias.makeRule "Types" "FrontendModel" "quot: String"

        type alias FrontendModel =
            { counter : Int
            , clientId : String
            , quot : String
            }

-}
makeRule : String -> String -> List String -> Rule
makeRule moduleName_ typeName_ fieldsDefinition_ =
    let
        fieldsName =
            List.map getFieldName fieldsDefinition_
                |> Set.fromList

        visitor : Node Declaration -> Context -> ( List (Error {}), Context )
        visitor =
            declarationVisitor moduleName_ typeName_ fieldsName fieldsDefinition_
    in
    Rule.newModuleRuleSchemaUsingContextCreator "Install.FieldInTypeAlias" contextCreator
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


declarationVisitor : String -> String -> Set String -> List String -> Node Declaration -> Context -> ( List (Error {}), Context )
declarationVisitor moduleName_ typeName_ fieldsName_ fieldsDefinition_ node context =
    case Node.value node of
        Declaration.AliasDeclaration type_ ->
            let
                isInCorrectModule =
                    Install.Library.isInCorrectModule moduleName_ context

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
                    not <| Set.Extra.isSubsetOf (Set.fromList fieldsOfNode_) fieldsName_
            in
            if isInCorrectModule && Node.value type_.name == typeName_ && shouldFix node then
                let
                    fieldsToAdd : Set String
                    fieldsToAdd =
                        Set.diff fieldsName_ (Set.fromList <| fieldsOfNode node)

                    getFieldCode field =
                        "    , " ++ field ++ "\n"

                    closeRecord =
                        "    }"

                    -- filter out the fields that are already in the type alias
                    newFields : List String
                    newFields =
                        fieldsDefinition_
                            |> List.filter (\field -> Set.member (getFieldName field) fieldsToAdd)

                    fieldsCode =
                        newFields
                            |> List.map getFieldCode
                            |> String.concat
                            |> (\fields -> fields ++ closeRecord)
                in
                ( [ errorWithFix typeName_ fieldsToAdd fieldsCode node (Just <| Node.range node) ]
                , context
                )

            else
                ( [], context )

        _ ->
            ( [], context )


getFieldName : String -> String
getFieldName field =
    field
        |> String.split ":"
        |> List.head
        |> Maybe.withDefault ""
        |> String.trim
