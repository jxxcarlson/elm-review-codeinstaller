module Install.Internal.TypeVariant exposing
    ( Config(..)
    , declarationVisitor
    )

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (Range)
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error)
import Set exposing (Set)
import Set.Extra


type Config
    = Config
        { hostModuleName : ModuleName
        , typeName : String
        , variants : List String
        }


declarationVisitor : Config -> Node Declaration -> List (Error {})
declarationVisitor (Config config) node =
    case Node.value node of
        Declaration.CustomTypeDeclaration type_ ->
            let
                variantName : String -> Maybe String
                variantName variantString =
                    variantString |> String.split " " |> List.head |> Maybe.map String.trim

                variantCodeItem variantString =
                    "\n    | " ++ variantString

                variantNames =
                    List.filterMap variantName config.variants

                shouldFix : Node Declaration -> Bool
                shouldFix node_ =
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
            if Node.value type_.name == config.typeName && shouldFix node then
                let
                    variantCode =
                        List.map variantCodeItem config.variants |> String.concat
                in
                [ errorWithFix config.typeName variantNames variantCode node (Just <| Node.range node) ]

            else
                []

        _ ->
            []


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
