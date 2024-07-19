module Install.ElementToList exposing (makeRule)

{-|

@docs makeRule

-}

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Location)
import Install.Library
import Review.Fix as Fix
import Review.Rule as Rule exposing (Rule)
import Set
import Set.Extra
import String.Extra


{-| Create a rule that adds elements to a list.

For example, the rule

    Install.ElementToList.makeRule "User" "userTypes" [ "Admin", "SystemAdmin" ]

results in the following fix for function `User.userTypes`:

    [ Standard ] -> [ Standard, Admin, SystemAdmin ]

-}
makeRule : String -> String -> List String -> Rule
makeRule moduleName functionName elements =
    let
        visitor =
            declarationVisitor moduleName functionName elements
    in
    Rule.newModuleRuleSchemaUsingContextCreator "Install.ElementToList" initialContext
        |> Rule.withDeclarationExitVisitor visitor
        |> Rule.providesFixesForModuleRule
        |> Rule.fromModuleRuleSchema


type alias Context =
    { moduleName : ModuleName
    }


initialContext : Rule.ContextCreator () Context
initialContext =
    Rule.initContextCreator
        (\moduleName () ->
            { moduleName = moduleName
            }
        )
        |> Rule.withModuleName


declarationVisitor : String -> String -> List String -> Node Declaration -> Context -> ( List (Rule.Error {}), Context )
declarationVisitor moduleName functionName items (Node _ declaration) context =
    if Install.Library.isInCorrectModule moduleName context then
        case declaration of
            FunctionDeclaration function ->
                if Install.Library.isInCorrectFunction functionName function then
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
                            ( [], context )

                        Just listElements ->
                            let
                                stringifiedExprs =
                                    listElements |> List.map Install.Library.expressionToString |> Set.fromList

                                isAlreadyImplemented =
                                    Set.Extra.isSubsetOf stringifiedExprs (Set.fromList items)
                            in
                            if isAlreadyImplemented then
                                ( [], context )

                            else
                                let
                                    replacementCode =
                                        items
                                            |> List.map (\item -> ", " ++ item)
                                            |> String.concat

                                    lastElementLocation =
                                        listElements
                                            |> List.reverse
                                            |> List.head
                                            |> Maybe.map (Node.range >> .end)
                                            |> Maybe.withDefault (Node.range expr).start
                                in
                                ( [ errorWithFix replacementCode expr lastElementLocation ], context )

                else
                    ( [], context )

            _ ->
                ( [], context )

    else
        ( [], context )


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
