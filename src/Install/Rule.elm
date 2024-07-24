module Install.Rule exposing (Installation, rule)

import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module exposing (Module)
import Elm.Syntax.Node exposing (Node)
import Install.Import
import Review.Rule as Rule exposing (Error, Rule)


type alias Context =
    { importContexts : List ( Install.Import.Config, Install.Import.Context )
    }


{-| A transformation to apply.
-}
type Installation
    = AddImport Install.Import.Config


{-| Create a rule from a list of transformations.
-}
rule : List Installation -> Rule
rule installations =
    Rule.newModuleRuleSchemaUsingContextCreator "Install.ClauseInCase" (initContext installations)
        |> Rule.withModuleDefinitionVisitor moduleDefinitionVisitor
        |> Rule.withImportVisitor importVisitor
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
                        AddImport config ->
                            { context | importContexts = ( config, Install.Import.init moduleName ) :: context.importContexts }
                )
                { importContexts = []
                }
                installations
        )
        |> Rule.withModuleName


moduleDefinitionVisitor : Node Module -> Context -> ( List (Error {}), Context )
moduleDefinitionVisitor node context =
    ( []
    , { importContexts =
            List.map
                (\( config, importContext ) -> ( config, Install.Import.moduleDefinitionVisitor node importContext ))
                context.importContexts
      }
    )


importVisitor : Node Import -> Context -> ( List (Error {}), Context )
importVisitor node context =
    ( []
    , { importContexts =
            List.map
                (\( config, importContext ) -> ( config, Install.Import.importVisitor config node importContext ))
                context.importContexts
      }
    )


finalEvaluation : Context -> List (Rule.Error {})
finalEvaluation context =
    List.concatMap
        (\( config, importContext ) -> Install.Import.finalEvaluation config importContext)
        context.importContexts
