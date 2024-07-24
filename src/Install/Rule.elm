module Install.Rule exposing
    ( rule
    , Installation
    , addImport, addElementToList
    )

{-| TODO REPLACEME

@docs rule

@docs Installation
@docs addImport, addElementToList

-}

import Elm.Syntax.Declaration exposing (Declaration)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module exposing (Module)
import Elm.Syntax.Node exposing (Node)
import Install.ElementToList
import Install.Import
import Install.Internal.ElementToList
import Install.Internal.Import
import Review.Rule as Rule exposing (Error, Rule)


type alias Context =
    { importContexts : List ( Install.Internal.Import.Config, Install.Internal.Import.Context )
    , elementToList : List Install.ElementToList.Config
    }


{-| A transformation to apply.
-}
type Installation
    = AddImport Install.Import.Config
    | AddElementToList Install.ElementToList.Config


{-| Add an import, defined by [`Install.Import.config`](Install-Import#config).
-}
addImport : Install.Import.Config -> Installation
addImport =
    AddImport


{-| Add an element to the end of a list, defined by [`Install.ElementToList.add`](Install-ElementToList#add).
-}
addElementToList : Install.ElementToList.Config -> Installation
addElementToList =
    AddElementToList


{-| Create a rule from a list of transformations.
-}
rule : String -> List Installation -> Rule
rule name installations =
    Rule.newModuleRuleSchemaUsingContextCreator name (initContext installations)
        |> Rule.withModuleDefinitionVisitor moduleDefinitionVisitor
        |> Rule.withImportVisitor importVisitor
        |> Rule.withDeclarationEnterVisitor declarationVisitor
        |> Rule.withFinalModuleEvaluation finalEvaluation
        |> Rule.providesFixesForModuleRule
        |> Rule.fromModuleRuleSchema


initContext : List Installation -> Rule.ContextCreator () Context
initContext installations =
    Rule.initContextCreator
        (\moduleName () ->
            List.foldl
                (\installation context ->
                    case installation of
                        AddImport ((Install.Internal.Import.Config { hostModuleName }) as config) ->
                            if moduleName == hostModuleName then
                                { context | importContexts = ( config, Install.Internal.Import.init ) :: context.importContexts }

                            else
                                context

                        AddElementToList ((Install.Internal.ElementToList.Config { hostModuleName }) as config) ->
                            if moduleName == hostModuleName then
                                { context | elementToList = config :: context.elementToList }

                            else
                                context
                )
                { importContexts = []
                , elementToList = []
                }
                installations
        )
        |> Rule.withModuleName


moduleDefinitionVisitor : Node Module -> Context -> ( List (Error {}), Context )
moduleDefinitionVisitor node context =
    ( []
    , { context
        | importContexts =
            List.map
                (\( config, importContext ) -> ( config, Install.Internal.Import.moduleDefinitionVisitor node importContext ))
                context.importContexts
      }
    )


importVisitor : Node Import -> Context -> ( List (Error {}), Context )
importVisitor node context =
    ( []
    , { context
        | importContexts =
            List.map
                (\( config, importContext ) -> ( config, Install.Internal.Import.importVisitor config node importContext ))
                context.importContexts
      }
    )


declarationVisitor : Node Declaration -> Context -> ( List (Rule.Error {}), Context )
declarationVisitor node context =
    ( List.concatMap
        (\config -> Install.Internal.ElementToList.declarationVisitor config node)
        context.elementToList
    , context
    )


finalEvaluation : Context -> List (Rule.Error {})
finalEvaluation context =
    List.concatMap
        (\( config, importContext ) -> Install.Internal.Import.finalEvaluation config importContext)
        context.importContexts
