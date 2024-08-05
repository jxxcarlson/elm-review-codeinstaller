module Install.Internal.Subscription exposing
    ( Config(..)
    , declarationVisitor
    )

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Location, Range)
import Install.Library
import Review.Fix as Fix
import Review.Rule as Rule exposing (Error)


type Config
    = Config
        { hostModuleName : ModuleName
        , subscriptions : List String
        }


declarationVisitor : Config -> Node Declaration -> List (Rule.Error {})
declarationVisitor (Config config) (Node _ declaration) =
    case declaration of
        FunctionDeclaration function ->
            let
                implementation =
                    Node.value function.declaration

                name : String
                name =
                    Node.value implementation.name
            in
            if name /= "subscriptions" then
                []

            else
                case Node.value implementation.expression of
                    Application ((Node _ (FunctionOrValue [ "Sub" ] "batch")) :: rest) ->
                        let
                            listElements =
                                rest
                                    |> List.head
                                    |> Maybe.map Node.value
                                    |> (\expression ->
                                            case expression of
                                                Just (ListExpr exprs) ->
                                                    exprs

                                                _ ->
                                                    []
                                       )

                            isAlreadyImplemented =
                                Install.Library.areItemsInList config.subscriptions listElements
                        in
                        if isAlreadyImplemented then
                            []

                        else
                            let
                                expr =
                                    implementation.expression

                                endOfRange =
                                    (Node.range expr).end

                                nameRange =
                                    Node.range implementation.name

                                replacementCode =
                                    config.subscriptions
                                        |> List.map (\item -> ", " ++ item)
                                        |> String.concat
                            in
                            [ errorWithFix replacementCode nameRange endOfRange ]

                    _ ->
                        []

        _ ->
            []


errorWithFix : String -> Range -> Location -> Error {}
errorWithFix replacementCode range endRange =
    Rule.errorWithFix
        { message = "Add to subscriptions: " ++ replacementCode
        , details =
            [ ""
            ]
        }
        range
        [ Fix.insertAt { endRange | column = endRange.column - 2 } replacementCode ]
