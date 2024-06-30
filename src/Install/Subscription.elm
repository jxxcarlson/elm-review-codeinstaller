module Install.Subscription exposing (makeRule)

{-| Use this rule to add to the list of subscriptions.

@docs makeRule

-}

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression(..), Function, FunctionImplementation)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range as Range exposing (Location, Range)
import Install.Library
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error, Rule)
import Set exposing (Set)


type alias Ignored =
    Set String


{-| Suppose that you have

    subscriptions =
        Sub.batch [ foo, bar ]

and that you want to add `baz` to the list. To do this, say

    Insall.Subscription.makeRule "Badkend" "baz"

The result is

    subscriptions =
        Sub.batch [ foo, bar, baz ]

-}
makeRule : String -> String -> Rule
makeRule moduleName item =
    let
        --visitor : Node Declaration -> Context -> ( List (Error {}), Context )
        visitor =
            declarationVisitor moduleName item
    in
    Rule.newModuleRuleSchemaUsingContextCreator "Install.Subscription" contextCreator
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


declarationVisitor : String -> String -> Node Declaration -> Context -> ( List (Rule.Error {}), Context )
declarationVisitor moduleName item (Node _ declaration) context =
    case declaration of
        FunctionDeclaration function ->
            let
                functionRange =
                    Node.range function.declaration |> Debug.log "\nFUNCTION RANGE"

                implementation =
                    Node.value function.declaration

                expr =
                    implementation.expression |> Debug.log "\nEXPRESSION"

                range =
                    Node.range expr |> Debug.log "\nRANGE"

                endOfRange =
                    (Node.range expr).end |> Debug.log "\nRANGE.END"

                name : String
                name =
                    Node.value implementation.name

                nameRange =
                    Node.range implementation.name |> Debug.log "\nNAME RANGE"

                data =
                    case Node.value implementation.expression of
                        Application (head :: rest) ->
                            Just ( head, rest )

                        _ ->
                            Nothing
            in
            if name /= "subscriptions" then
                ( [], context )

            else
                case data of
                    Nothing ->
                        ( [], context )

                    Just ( head, rest ) ->
                        case Node.value head of
                            FunctionOrValue [ "Sub" ] "batch" ->
                                let
                                    _ =
                                        Debug.log "\nSUBSCRIPTION LIST" rest

                                    foo : List (Node Expression)
                                    foo =
                                        rest
                                in
                                ( [ errorWithFix (", " ++ item) nameRange endOfRange rest ], context )

                            _ ->
                                ( [], context )

        _ ->
            ( [], context )


errorWithFix : String -> Range -> Location -> List (Node Expression) -> Error {}
errorWithFix replacementCode range endRange subList =
    let
        _ =
            Debug.log "\nERROR WITH FIX, RANGE" range
    in
    Rule.errorWithFix
        { message = "Add to subscriptions: " ++ replacementCode
        , details =
            [ ""
            ]
        }
        range
        [ Fix.insertAt { endRange | column = endRange.column - 2 } replacementCode ]
        |> Debug.log "\nFIX"
