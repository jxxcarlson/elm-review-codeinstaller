module Install.Subscription exposing (makeRule)

{-| Use this rule to add to the list of subscriptions.

@docs makeRule

-}

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Location, Range)
import Install.Library
import Review.Fix as Fix
import Review.Rule as Rule exposing (Error, Rule)


{-| Suppose that you have the following code in your `Backend.elm` file:

    subscriptions =
        Sub.batch [ foo, bar ]

and that you want to add `baz` to the list. To do this, say

    Install.Subscription.makeRule "Backend" [ "baz" ]

The result is

    subscriptions =
        Sub.batch [ foo, bar, baz ]

-}
makeRule : String -> List String -> Rule
makeRule moduleName subscriptions =
    let
        --visitor : Node Declaration -> Context -> ( List (Error {}), Context )
        visitor =
            declarationVisitor moduleName subscriptions
    in
    Rule.newModuleRuleSchemaUsingContextCreator "Install.Subscription" contextCreator
        |> Rule.withDeclarationEnterVisitor visitor
        |> Rule.providesFixesForModuleRule
        |> Rule.fromModuleRuleSchema


type alias Context =
    { moduleName : ModuleName
    }


contextCreator : Rule.ContextCreator () Context
contextCreator =
    Rule.initContextCreator
        (\moduleName () ->
            { moduleName = moduleName

            -- ...other fields
            }
        )
        |> Rule.withModuleName


declarationVisitor : String -> List String -> Node Declaration -> Context -> ( List (Rule.Error {}), Context )
declarationVisitor moduleName items (Node _ declaration) context =
    if Install.Library.isInCorrectModule moduleName context then
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
                    ( [], context )

                else
                    let
                        data =
                            case Node.value implementation.expression of
                                Application (head :: rest) ->
                                    Just ( head, rest )

                                _ ->
                                    Nothing
                    in
                    case data of
                        Nothing ->
                            ( [], context )

                        Just ( head, rest ) ->
                            case Node.value head of
                                FunctionOrValue [ "Sub" ] "batch" ->
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
                                            Install.Library.areItemsInList items listElements
                                    in
                                    if isAlreadyImplemented then
                                        ( [], context )

                                    else
                                        let
                                            expr =
                                                implementation.expression

                                            endOfRange =
                                                (Node.range expr).end

                                            nameRange =
                                                Node.range implementation.name

                                            replacementCode =
                                                items
                                                    |> List.map (\item -> ", " ++ item)
                                                    |> String.concat
                                        in
                                        ( [ errorWithFix replacementCode nameRange endOfRange rest ], context )

                                _ ->
                                    ( [], context )

            _ ->
                ( [], context )

    else
        ( [], context )


errorWithFix : String -> Range -> Location -> List (Node Expression) -> Error {}
errorWithFix replacementCode range endRange subList =
    Rule.errorWithFix
        { message = "Add to subscriptions: " ++ replacementCode
        , details =
            [ ""
            ]
        }
        range
        [ Fix.insertAt { endRange | column = endRange.column - 2 } replacementCode ]
