module Install.Internal.Type exposing
    ( Config(..)
    , Context
    , declarationVisitor
    , finalEvaluation
    , importVisitor
    , init
    )

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range as Range exposing (Range)
import List.Extra
import Review.Fix as Fix
import Review.Rule as Rule exposing (Error)


type Config
    = Config
        { hostModuleName : ModuleName
        , typeName : String
        , variants : List String
        }


type alias Context =
    { typeIsPresent : Bool
    , lastNodeRange : Range
    }


init : Context
init =
    { typeIsPresent = False
    , lastNodeRange = Range.empty
    }


importVisitor : Node Import -> Context -> Context
importVisitor node context =
    { context | lastNodeRange = Node.range node }


declarationVisitor : Config -> Node Declaration -> Context -> Context
declarationVisitor (Config config) node context =
    case Node.value node of
        Declaration.CustomTypeDeclaration type_ ->
            if Node.value type_.name == config.typeName then
                { context | typeIsPresent = True, lastNodeRange = Node.range node }

            else
                { context | lastNodeRange = Node.range node }

        _ ->
            context


finalEvaluation : Config -> Context -> List (Rule.Error {})
finalEvaluation (Config config) context =
    if context.typeIsPresent == False then
        fixError config.typeName config.variants context

    else
        []


fixError : String -> List String -> Context -> List (Error {})
fixError typeName_ variants_ context =
    let
        codeToAdd =
            case List.Extra.uncons variants_ of
                Nothing ->
                    ""

                Just ( head, tail ) ->
                    "\n"
                        ++ (String.join "  " [ "type", typeName_, "=" ]
                                :: ("    " ++ head)
                                :: List.map (\s -> "  | " ++ s) tail
                                |> String.join "\n"
                           )
    in
    [ Rule.errorWithFix
        { message = "add type: \"" ++ typeName_, details = [ "" ] }
        context.lastNodeRange
        [ Fix.insertAt { row = context.lastNodeRange.end.row + 2, column = 0 } codeToAdd ]
    ]
