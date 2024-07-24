module Install.Internal.ElementToList exposing
    ( Config(..)
    , declarationVisitor
    )

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Location)
import Install.Library
import Review.Fix as Fix
import Review.Rule as Rule
import String.Extra


type Config
    = Config
        { hostModuleName : ModuleName
        , functionName : String
        , elements : List String
        }


declarationVisitor : Config -> Node Declaration -> List (Rule.Error {})
declarationVisitor (Config config) (Node _ declaration) =
    case declaration of
        FunctionDeclaration function ->
            if Install.Library.isInCorrectFunction config.functionName function then
                let
                    implementation =
                        Node.value function.declaration

                    expr =
                        implementation.expression

                    data =
                        case Node.value expr of
                            ListExpr nodes ->
                                Just nodes

                            _ ->
                                Nothing
                in
                case data of
                    Nothing ->
                        []

                    Just listElements ->
                        let
                            isAlreadyImplemented =
                                Install.Library.areItemsInList config.elements listElements
                        in
                        if isAlreadyImplemented then
                            []

                        else
                            let
                                replacementCode =
                                    config.elements
                                        |> List.map (\item -> ", " ++ item)
                                        |> String.concat

                                lastElementLocation =
                                    listElements
                                        |> List.reverse
                                        |> List.head
                                        |> Maybe.map (Node.range >> .end)
                                        |> Maybe.withDefault (Node.range expr).start
                            in
                            [ errorWithFix replacementCode expr lastElementLocation ]

            else
                []

        _ ->
            []


errorWithFix : String -> Node Expression -> Location -> Rule.Error {}
errorWithFix replacementCode expression lastElementLocation =
    let
        numberOfElementsAdded =
            String.Extra.countOccurrences ", " replacementCode

        replacementText =
            if numberOfElementsAdded == 1 then
                "1 element"

            else
                String.fromInt numberOfElementsAdded ++ " elements"
    in
    Rule.errorWithFix
        { message = "Add " ++ replacementText ++ " to the list"
        , details =
            [ ""
            ]
        }
        (Node.range expression)
        [ Fix.insertAt
            { row = lastElementLocation.row
            , column = lastElementLocation.column
            }
            (String.Extra.clean replacementCode)
        ]
