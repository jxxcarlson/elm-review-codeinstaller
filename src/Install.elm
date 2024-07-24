module Install exposing
    ( rule
    , Installation
    , addImport, addElementToList, insertFunction
    )

{-| TODO REPLACEME

@docs rule

@docs Installation
@docs addImport, addElementToList, insertFunction

-}

import Elm.Syntax.Declaration exposing (Declaration)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module exposing (Module)
import Elm.Syntax.Node exposing (Node)
import Install.ElementToList
import Install.Function.InsertFunction
import Install.Import
import Install.Internal.ElementToList
import Install.Internal.Import
import Install.Internal.InsertFunction
import Review.Rule as Rule exposing (Error, Rule)


type alias Context =
    { importContexts : List ( Install.Internal.Import.Config, Install.Internal.Import.Context )
    , elementToList : List Install.ElementToList.Config
    , insertFunction : List ( Install.Function.InsertFunction.Config, Install.Internal.InsertFunction.Context )
    }


{-| A transformation to apply.
-}
type Installation
    = AddImport Install.Import.Config
    | AddElementToList Install.ElementToList.Config
    | InsertFunction Install.Function.InsertFunction.Config


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


{-| Insert a function, defined by [`Install.Function.InsertFunction.insert`](Install-Function-InsertFunction#insert).
-}
insertFunction : Install.Function.InsertFunction.Config -> Installation
insertFunction =
    InsertFunction


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

                        InsertFunction ((Install.Internal.InsertFunction.Config { hostModuleName }) as config) ->
                            if moduleName == hostModuleName then
                                { context | insertFunction = ( config, Install.Internal.InsertFunction.init ) :: context.insertFunction }

                            else
                                context
                )
                { importContexts = []
                , elementToList = []
                , insertFunction = []
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
                (\( config, ctx ) -> ( config, Install.Internal.Import.moduleDefinitionVisitor node ctx ))
                context.importContexts
      }
    )


importVisitor : Node Import -> Context -> ( List (Error {}), Context )
importVisitor node context =
    ( []
    , { context
        | importContexts =
            List.map
                (\( config, ctx ) -> ( config, Install.Internal.Import.importVisitor config node ctx ))
                context.importContexts
      }
    )


declarationVisitor : Node Declaration -> Context -> ( List (Rule.Error {}), Context )
declarationVisitor node context =
    ( List.concatMap
        (\config -> Install.Internal.ElementToList.declarationVisitor config node)
        context.elementToList
    , { context
        | insertFunction =
            List.map
                (\( config, ctx ) -> ( config, Install.Internal.InsertFunction.declarationVisitor config node ctx ))
                context.insertFunction
      }
    )


finalEvaluation : Context -> List (Rule.Error {})
finalEvaluation context =
    List.concat
        [ List.concatMap
            (\( config, ctx ) -> Install.Internal.Import.finalEvaluation config ctx)
            context.importContexts
        , List.concatMap
            (\( config, ctx ) -> Install.Internal.InsertFunction.finalEvaluation config ctx)
            context.insertFunction
        ]
