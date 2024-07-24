module Install.Rule exposing
    ( rule
    , Installation
    , addImport
    )

{-| TODO REPLACEME

@docs rule

@docs Installation
@docs addImport

-}

import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module exposing (Module)
import Elm.Syntax.Node exposing (Node)
import Install.Import as Import
import Install.Internal.Import
import Review.Rule as Rule exposing (Error, Rule)


type alias Context =
    { importContexts : List ( Install.Internal.Import.Config, Install.Internal.Import.Context )
    }


{-| A transformation to apply.
-}
type Installation
    = AddImport Import.Config


{-| Add an import defined by [Install-Import#config].
-}
addImport : Import.Config -> Installation
addImport =
    AddImport


{-| Create a rule from a list of transformations.
-}
rule : String -> List Installation -> Rule
rule name installations =
    Rule.newModuleRuleSchemaUsingContextCreator name (initContext installations)
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
                            { context | importContexts = ( config, Install.Internal.Import.init moduleName ) :: context.importContexts }
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
                (\( config, importContext ) -> ( config, Install.Internal.Import.moduleDefinitionVisitor node importContext ))
                context.importContexts
      }
    )


importVisitor : Node Import -> Context -> ( List (Error {}), Context )
importVisitor node context =
    ( []
    , { importContexts =
            List.map
                (\( config, importContext ) -> ( config, Install.Internal.Import.importVisitor config node importContext ))
                context.importContexts
      }
    )


finalEvaluation : Context -> List (Rule.Error {})
finalEvaluation context =
    List.concatMap
        (\( config, importContext ) -> Install.Internal.Import.finalEvaluation config importContext)
        context.importContexts
