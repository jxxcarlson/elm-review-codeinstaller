module Install.TypeVariant exposing (makeRule)

{-| Add a variant to a given type in a given module. As in
the `ReviewConfig` item below, you specify the module name, the type
name, and the type of the new variant.

    Install.TypeVariant.makeRule "Types" "ToBackend" "ResetCounter"

Then you will have

     type ToBackend
         = CounterIncremented
         | CounterDecremented
         | ResetCounter

where the last variant is the one added.

@docs makeRule

-}

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (Range)
import Install.Library
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error, Rule)


{-| Create a rule that adds a variant to a type in a specified module:

    Install.TypeVariant.makeRule "Types" "ToBackend" "ResetCounter"

-}
makeRule : String -> String -> String -> Rule
makeRule moduleName typeName_ variant_ =
    let
        variantName_ =
            variant_
                |> String.split " "
                |> List.head
                |> Maybe.withDefault ""
                |> String.trim

        variantCode_ =
            "\n    | " ++ variant_

        visitor : Node Declaration -> Context -> ( List (Error {}), Context )
        visitor =
            declarationVisitor moduleName typeName_ variantName_ variantCode_
    in
    Rule.newModuleRuleSchemaUsingContextCreator "Install.TypeVariant" contextCreator
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


errorWithFix : String -> String -> String -> Node a -> Maybe Range -> Error {}
errorWithFix typeName_ variantName_ variantCode_ node errorRange =
    Rule.errorWithFix
        { message = "Add " ++ variantName_ ++ " to " ++ typeName_
        , details =
            [ ""
            ]
        }
        (Node.range node)
        (case errorRange of
            Just range ->
                [ fixMissingVariant range.end variantCode_ ]

            Nothing ->
                []
        )


fixMissingVariant : { row : Int, column : Int } -> String -> Fix
fixMissingVariant { row, column } variantCode =
    Fix.insertAt { row = row, column = column } variantCode


declarationVisitor : String -> String -> String -> String -> Node Declaration -> Context -> ( List (Error {}), Context )
declarationVisitor moduleName_ typeName_ variantName_ variantCode_ node context =
    case Node.value node of
        Declaration.CustomTypeDeclaration type_ ->
            let
                isInCorrectModule =
                    Install.Library.isInCorrectModule moduleName_ context

                shouldFix : Node Declaration -> Context -> Bool
                shouldFix node_ context_ =
                    let
                        variantsOfNode : List String
                        variantsOfNode =
                            case Node.value node_ of
                                Declaration.CustomTypeDeclaration type__ ->
                                    type__.constructors |> List.map (Node.value >> .name >> Node.value)

                                _ ->
                                    []
                    in
                    not <| List.member variantName_ variantsOfNode
            in
            if isInCorrectModule && Node.value type_.name == typeName_ && shouldFix node context then
                ( [ errorWithFix typeName_ variantName_ variantCode_ node (Just <| Node.range node) ]
                , context
                )

            else
                ( [], context )

        _ ->
            ( [], context )
