module Install.Initializer exposing (makeRule)

{-| Add field = value pairs to the body of a function like `init` in which the
the return value is of the form `( SomeTypeAlias, Cmd msg )`. As in
the `ReviewConfig` item below, you specify the module name, the function
name, as well as a list of item `{field = <fieldName>, value = <value>}`
to be added to the function.

    Install.Initializer.makeRule "Main"
        "init"
        [ { field = "message", value = "\"hohoho!\"" }, { field = "counter", value = "0" } ]

Thus we will have

     init : ( Model, Cmd BackendMsg )
     init =
         ( { counter = 0
           , message = "hohoho!"
           , counter = 0
           }
         , Cmd.none
         )

@docs makeRule

-}

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression(..), Function, FunctionImplementation)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (Range)
import Install.Library
import List.Extra
import Review.Fix as Fix exposing (Fix)
import Review.Rule as Rule exposing (Error, Rule)
import Set exposing (Set)
import Set.Extra


type alias Ignored =
    Set String


{-| Create a rule that adds fields to the body of a function like
`init` in which the return value is of the form `( Model, Cmd msg )`.
As in the `ReviewConfig` item below, you specify
the module name, the function name, as well as the
field name and value to be added to the function:

    Install.Initializer.makeRule "Main"
        "init"
        [ { field = "message", value = "\"hohoho!\"" }, { field = "counter", value = "0" } ]

-}
makeRule : String -> String -> List { field : String, value : String } -> Rule
makeRule moduleName functionName data =
    let
        visitor : Node Declaration -> Context -> ( List (Error {}), Context )
        visitor =
            declarationVisitor moduleName functionName data
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


declarationVisitor : String -> String -> List { field : String, value : String } -> Node Declaration -> Context -> ( List (Rule.Error {}), Context )
declarationVisitor moduleName functionName data (Node _ declaration) context =
    case declaration of
        FunctionDeclaration function ->
            let
                name : String
                name =
                    Node.value (Node.value function.declaration).name

                isInCorrectModule =
                    Install.Library.isInCorrectModule moduleName context
            in
            if name == functionName && isInCorrectModule then
                visitFunction data Set.empty function context

            else
                ( [], context )

        _ ->
            ( [], context )


visitFunction : List { field : String, value : String } -> Ignored -> Function -> Context -> ( List (Rule.Error {}), Context )
visitFunction data ignored function context =
    let
        declaration : FunctionImplementation
        declaration =
            Node.value function.declaration

        ( fieldNames, lastRange ) =
            getFieldNamesAndLastRange (Node.value declaration.expression)

        existingFields =
            Set.fromList fieldNames

        newFields =
            List.map .field data |> Set.fromList
    in
    if not <| Set.Extra.isSubsetOf existingFields newFields then
        ( [ errorWithFix data function.declaration (Just lastRange) ], context )

    else
        ( [], context )


errorWithFix : List { field : String, value : String } -> Node a -> Maybe Range -> Error {}
errorWithFix data node errorRange =
    Rule.errorWithFix
        { message = "Add fields to the model"
        , details =
            [ ""
            ]
        }
        (Node.range node)
        (case errorRange of
            Just range ->
                let
                    insertionPoint =
                        { row = range.end.row, column = range.end.column }
                in
                [ addMissingCases insertionPoint data ]

            Nothing ->
                []
        )


addMissingCases : { row : Int, column : Int } -> List { field : String, value : String } -> Fix
addMissingCases insertionPoint data =
    let
        insertion =
            ", " ++ (List.map (\{ field, value } -> field ++ " = " ++ value) data |> String.join ", ")
    in
    Fix.insertAt
        { row = insertionPoint.row
        , column = insertionPoint.column
        }
        insertion


getFieldNamesAndLastRange : Expression -> ( List String, Range )
getFieldNamesAndLastRange expr =
    case expr of
        TupledExpression expressions ->
            let
                lastRange_ =
                    case expressions |> List.head |> Maybe.map Node.value of
                        Just expression ->
                            Install.Library.lastRange expression

                        Nothing ->
                            Elm.Syntax.Range.empty

                fieldNames_ : List String
                fieldNames_ =
                    case expressions |> List.map Node.value |> List.head of
                        Just recordExpr ->
                            Install.Library.fieldNames recordExpr

                        Nothing ->
                            []
            in
            ( fieldNames_, lastRange_ )

        LetExpression { expression } ->
            getFieldNamesAndLastRange (Node.value expression)

        Application children ->
            children
                |> List.Extra.find
                    (\child ->
                        case Node.value child of
                            TupledExpression _ ->
                                True

                            _ ->
                                False
                    )
                |> Maybe.map Node.value
                |> Maybe.withDefault (TupledExpression [])
                |> getFieldNamesAndLastRange

        _ ->
            ( [], Elm.Syntax.Range.empty )
