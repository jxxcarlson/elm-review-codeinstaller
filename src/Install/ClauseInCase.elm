module Install.ClauseInCase exposing (makeRule)

{-| Add a clause to a case expression in a specified function
in a specified module. For example, if you put the code below in your
`ReviewConfig.elm` file, running `elm-review` will add the clause
`ResetCounter` to the `updateFromFrontend` function in the `Backend` module.

    -- code for ReviewConfig.elm:
    Install.ClauseInCase.makeRule
        "Backend"
        "updateFromFrontend"
        "ResetCounter"
        "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"

    Thus we will have

    updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
    updateFromFrontend sessionId clientId msg model =
        case msg of
            CounterIncremented ->
            ...

            ResetCounter ->
                ( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )

@docs makeRule

-}

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Case, CaseBlock, Expression(..), Function, FunctionImplementation, Lambda, LetBlock, LetDeclaration(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..), range)
import Elm.Syntax.Pattern exposing (Pattern(..))
import Elm.Syntax.Range exposing (Range)
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error, Rule)
import Set exposing (Set)


{-| Create a rule that adds a clause to a case expression in a specified function
-}
makeRule : String -> String -> String -> String -> Rule
makeRule moduleName functionName clause functionCall =
    let
        visitor : Node Declaration -> Context -> ( List (Error {}), Context )
        visitor =
            declarationVisitor moduleName functionName clause functionCall
    in
    Rule.newModuleRuleSchemaUsingContextCreator "Install.ClauseInCase" contextCreator
        |> Rule.withDeclarationEnterVisitor visitor
        |> Rule.providesFixesForModuleRule
        |> Rule.fromModuleRuleSchema


type alias Context =
    { moduleName : ModuleName
    }


type alias Ignored =
    Set String


contextCreator : Rule.ContextCreator () { moduleName : ModuleName }
contextCreator =
    Rule.initContextCreator
        (\moduleName () ->
            { moduleName = moduleName

            -- ...other fields
            }
        )
        |> Rule.withModuleName


declarationVisitor : String -> String -> String -> String -> Node Declaration -> Context -> ( List (Rule.Error {}), Context )
declarationVisitor moduleName functionName clause functionCall (Node _ declaration) context =
    case declaration of
        FunctionDeclaration function ->
            let
                name : String
                name =
                    Node.value (Node.value function.declaration).name

                namespace : String
                namespace =
                    String.join "." context.moduleName ++ "." ++ name
            in
            if name == functionName && moduleName == String.join "." context.moduleName then
                visitFunction namespace clause functionCall Set.empty function context

            else
                ( [], context )

        _ ->
            ( [], context )


visitFunction : String -> String -> String -> Ignored -> Function -> Context -> ( List (Rule.Error {}), Context )
visitFunction namespace clause functionCall ignored function context =
    let
        declaration : FunctionImplementation
        declaration =
            Node.value function.declaration
    in
    case declaration.expression |> Node.value of
        CaseExpression { expression, cases } ->
            let
                getPatterns : List Case -> List Pattern
                getPatterns cases_ =
                    cases_
                        |> List.map (\( pattern, _ ) -> Node.value pattern)

                findClause : String -> List Case -> Bool
                findClause clause_ cases_ =
                    List.any
                        (\pattern ->
                            case pattern of
                                NamedPattern qualifiedNameRef _ ->
                                    qualifiedNameRef.name == clause_

                                _ ->
                                    False
                        )
                        (getPatterns cases_)
            in
            if not (findClause clause cases) then
                ( [ errorWithFix clause functionCall declaration.expression (Just <| Node.range declaration.expression) ], context )

            else
                ( [], context )

        _ ->
            ( [], context )


errorWithFix : String -> String -> Node a -> Maybe Range -> Error {}
errorWithFix clause functionCall node errorRange =
    Rule.errorWithFix
        { message = "Add handler for " ++ clause
        , details =
            [ "This addition is required to add magic-token authentication to your application"
            ]
        }
        (Node.range node)
        (case errorRange of
            Just range ->
                let
                    insertionPoint =
                        { row = range.end.row + 2, column = 0 }
                in
                [ addMissingCase insertionPoint clause functionCall ]

            Nothing ->
                []
        )


addMissingCase : { row : Int, column : Int } -> String -> String -> Fix
addMissingCase { row, column } clause functionCall =
    let
        insertion =
            "\n\n        " ++ clause ++ " -> " ++ functionCall
    in
    Fix.insertAt { row = row, column = column } insertion
