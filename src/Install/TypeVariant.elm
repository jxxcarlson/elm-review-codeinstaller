module Install.TypeVariant exposing (makeRule)

{-| Add a variant to a given type in a given module. As in
the `ReviewConfig` item below, you specify the module name, the type
name, and the type of the new variant.

    Install.TypeVariant.makeRule "Types" "ToBackend" [ "ResetCounter" "SetCounter Int" ]

Then you will have

     type ToBackend
         = CounterIncremented
         | CounterDecremented
         | ResetCounter
         | SetCounter Int

where the last two variants are the ones added.

@docs makeRule

-}

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (Range)
import Install.Library
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error, Rule)
import Set exposing (Set)
import Set.Extra


{-| Create a rule that adds variants to a type in a specified module:

    Install.TypeVariant.makeRule "Types" "ToBackend" [ "ResetCounter", "SetCounter: Int" ]

-}
makeRule : String -> String -> List String -> Rule
makeRule moduleName typeName_ variantList =
    let
        visitor : Node Declaration -> Context -> ( List (Error {}), Context )
        visitor =
            declarationVisitor moduleName typeName_ variantList
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


errorWithFix : String -> List String -> String -> Node a -> Maybe Range -> Error {}
errorWithFix typeName_ variantNames variantCode node errorRange =
    Rule.errorWithFix
        { message = "Add variants [" ++ String.join ", " variantNames ++ "] to " ++ typeName_
        , details =
            [ ""
            ]
        }
        (Node.range node)
        (case errorRange of
            Just range ->
                [ fixMissingVariant range.end variantCode ]

            Nothing ->
                []
        )


fixMissingVariant : { row : Int, column : Int } -> String -> Fix
fixMissingVariant { row, column } variantCode =
    Fix.insertAt { row = row, column = column } variantCode


declarationVisitor : String -> String -> List String -> Node Declaration -> Context -> ( List (Error {}), Context )
declarationVisitor moduleName typeName variantList node context =
    case Node.value node of
        Declaration.CustomTypeDeclaration type_ ->
            let
                isInCorrectModule =
                    Install.Library.isInCorrectModule moduleName context

                variantName : String -> Maybe String
                variantName variantString =
                    variantString |> String.split " " |> List.head |> Maybe.map String.trim

                variantCodeItem variantString =
                    "\n    | " ++ variantString

                variantNames =
                    List.map variantName variantList |> List.filterMap identity

                variantCode =
                    List.map variantCodeItem variantList |> String.join ""

                shouldFix : Node Declaration -> Context -> Bool
                shouldFix node_ context_ =
                    let
                        variantsOfNode : Set String
                        variantsOfNode =
                            case Node.value node_ of
                                Declaration.CustomTypeDeclaration type__ ->
                                    type__.constructors
                                        |> List.map (Node.value >> .name >> Node.value)
                                        |> Set.fromList

                                _ ->
                                    Set.empty
                    in
                    not <| Set.Extra.isSubsetOf variantsOfNode (Set.fromList variantNames)
            in
            if isInCorrectModule && Node.value type_.name == typeName && shouldFix node context then
                ( [ errorWithFix typeName variantNames variantCode node (Just <| Node.range node) ]
                , context
                )

            else
                ( [], context )

        _ ->
            ( [], context )
