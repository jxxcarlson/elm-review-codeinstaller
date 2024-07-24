module Install.InitializerCmd exposing (makeRule)

{-| Consider a function whose return value is of the form `( _, Cmd.none )`.
Suppose given a list of commands, e.g. `[foo, bar]`. The function
`makeRule` described below replaces `Cmd.none` by `Cmd.batch [ foo, bar ]`.

@docs makeRule

-}

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression(..), Function, FunctionImplementation)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Range)
import Install.Library
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error, Rule)
import Set exposing (Set)


type alias Ignored =
    Set String


{-| Consider a function whose return value is of the form `( _, Cmd.none )`.
Suppose given a list of commands, e.g. `[foo, bar]`. The function
`makeRule` creates a rule that replaces `Cmd.none` by `Cmd.batch [ foo, bar ]`.
For example, the rule

    Install.InitializerCmd.makeRule "A.B" "init" [ "foo", "bar" ]

results in the following fix for function `A.B.init`:

    Cmd.none -> (Cmd.batch [ foo, bar ])

-}
makeRule : String -> String -> List String -> Rule
makeRule moduleName functionName cmds =
    let
        visitor : Node Declaration -> Context -> ( List (Error {}), Context )
        visitor =
            declarationVisitor moduleName functionName cmds
    in
    Rule.newModuleRuleSchemaUsingContextCreator "Install.Initializer" contextCreator
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


declarationVisitor : String -> String -> List String -> Node Declaration -> Context -> ( List (Rule.Error {}), Context )
declarationVisitor moduleName functionName cmds (Node _ declaration) context =
    case declaration of
        FunctionDeclaration function ->
            let
                name : String
                name =
                    Node.value (Node.value function.declaration).name
            in
            if name == functionName then
                let
                    namespace : String
                    namespace =
                        String.join "." context.moduleName ++ "." ++ name
                in
                visitCmd namespace moduleName functionName cmds Set.empty function context

            else
                ( [], context )

        _ ->
            ( [], context )


visitCmd : String -> String -> String -> List String -> Ignored -> Function -> Context -> ( List (Rule.Error {}), Context )
visitCmd namespace moduleName functionName cmds ignored function context =
    let
        declaration : FunctionImplementation
        declaration =
            Node.value function.declaration

        isInCorrectModule =
            Install.Library.isInCorrectModule moduleName context

        ( val, range ) =
            case declaration.expression |> Node.value of
                TupledExpression expressions ->
                    case expressions of
                        [ _, oldCmds ] ->
                            let
                                range_ =
                                    Node.range oldCmds
                            in
                            ( Just oldCmds, range_ )

                        _ ->
                            ( Nothing, Elm.Syntax.Range.empty )

                _ ->
                    ( Nothing, Elm.Syntax.Range.empty )

        stringifiedCmds =
            Maybe.map Install.Library.expressionToString val
    in
    if isInCorrectModule && stringifiedCmds == Just "Cmd.none" then
        ( [ errorWithFix cmds function.declaration (Just range) ], context )

    else
        ( [], context )



--if isInCorrectModule then
--    ( [ errorWithFix cmds function.declaration (Just lastRange) ], context )
--
--else
--    ( [], context )


errorWithFix : List String -> Node a -> Maybe Range -> Error {}
errorWithFix cmds node errorRange =
    Rule.errorWithFix
        { message = "Add cmds " ++ String.join ", " cmds ++ " to the model"
        , details =
            [ ""
            ]
        }
        (Node.range node)
        (case errorRange of
            Just range ->
                [ replaceCmds range cmds ]

            Nothing ->
                []
        )



--  Cmd.none -> (FunctionOrValue ["Cmd"] "none")
-- hohoho -> (FunctionOrValue [] "hohoho")


replaceCmds : Range -> List String -> Fix
replaceCmds rangeToReplace cmds =
    let
        replacement =
            "Cmd.batch [ " ++ String.join ", " cmds ++ " ]"
    in
    Fix.replaceRangeBy rangeToReplace replacement
