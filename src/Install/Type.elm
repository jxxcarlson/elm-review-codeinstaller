module Install.Type exposing (makeRule)

{-| `Install.Type` provides a rule that checks if a type is present
in the given module and if not, it adds it right after the imports.

For example, the rule

          Install.Type.makeRule "Frontend" "Magic" [ "Inactive", "Wizard String", "Spell String Int"]

results in insertion the text below in the module "Frontend":

          type Magic
              = Inactive
              | Wizard String
              | Spell String Int

@docs makeRule

-}

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range as Range exposing (Range)
import Install.Library
import List.Extra
import Review.Fix as Fix
import Review.Rule as Rule exposing (Error, Rule)


{-| Rule to add a type to a module if it is not present
-}
makeRule : String -> String -> List String -> Rule
makeRule hostModuleName typeName_ variants_ =
    let
        visitor : Node Declaration -> Context -> ( List (Error {}), Context )
        visitor =
            declarationVisitor hostModuleName typeName_
    in
    Rule.newModuleRuleSchemaUsingContextCreator "Install.Type" initialContext
        |> Rule.withImportVisitor importVisitor
        |> Rule.withDeclarationEnterVisitor visitor
        |> Rule.withFinalModuleEvaluation (finalEvaluation hostModuleName typeName_ variants_)
        |> Rule.providesFixesForModuleRule
        |> Rule.fromModuleRuleSchema


importVisitor : Node Import -> Context -> ( List (Error {}), Context )
importVisitor node context =
    ( [], { context | lastNodeRange = Node.range node } )


finalEvaluation : String -> String -> List String -> Context -> List (Rule.Error {})
finalEvaluation hostModuleName typeName_ variants_ context =
    if context.typeIsPresent == False && String.split "." hostModuleName == context.moduleName then
        fixError typeName_ variants_ context

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


declarationVisitor : String -> String -> Node Declaration -> Context -> ( List (Error {}), Context )
declarationVisitor moduleName_ typeName_ node context =
    case Node.value node of
        Declaration.CustomTypeDeclaration type_ ->
            let
                isInCorrectModule =
                    Install.Library.isInCorrectModule moduleName_ context
            in
            if isInCorrectModule && Node.value type_.name == typeName_ then
                ( [], { context | typeIsPresent = True, lastNodeRange = Node.range node } )

            else
                ( [], { context | lastNodeRange = Node.range node } )

        _ ->
            ( [], context )



--moduleDefinitionVisitor : Node Module -> Context -> ( List (Error {}), Context )
--moduleDefinitionVisitor def context =
--    -- visit the module definition to set the module definition as the lastNodeRange in case the module has no types yet TODO: ??
--    ( [], { context | lastNodeRange = Node.range def } )


type alias Context =
    { moduleName : ModuleName
    , typeIsPresent : Bool
    , lastNodeRange : Range
    }


initialContext : Rule.ContextCreator () Context
initialContext =
    Rule.initContextCreator
        (\moduleName () -> { moduleName = moduleName, typeIsPresent = False, lastNodeRange = Range.empty })
        |> Rule.withModuleName
