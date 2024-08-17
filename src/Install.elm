module Install exposing
    ( rule
    , Installation
    , imports, elementToList, function, replaceFunction, clauseInCase, fieldInTypeAlias, initializer, initializerCmd, subscription, customType, typeVariant
    )

{-|

@docs rule

@docs Installation
@docs imports, elementToList, function, replaceFunction, clauseInCase, fieldInTypeAlias, initializer, initializerCmd, subscription, customType, typeVariant

-}

import Elm.Syntax.Declaration exposing (Declaration)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module exposing (Module)
import Elm.Syntax.Node exposing (Node)
import Install.ClauseInCase
import Install.ElementToList
import Install.FieldInTypeAlias
import Install.Function.InsertFunction
import Install.Function.ReplaceFunction
import Install.Import
import Install.Initializer
import Install.InitializerCmd
import Install.Internal.ClauseInCase
import Install.Internal.ElementToList
import Install.Internal.FieldInTypeAlias
import Install.Internal.Import
import Install.Internal.Initializer
import Install.Internal.InitializerCmd
import Install.Internal.InsertFunction
import Install.Internal.ReplaceFunction
import Install.Internal.Subscription
import Install.Internal.Type
import Install.Internal.TypeVariant
import Install.Subscription
import Install.Type
import Install.TypeVariant
import Review.Rule as Rule exposing (Error, Rule)


type alias Context =
    { importContexts : List ( Install.Internal.Import.Config, Install.Internal.Import.Context )
    , elementToList : List Install.ElementToList.Config
    , function : List ( Install.Function.InsertFunction.Config, Install.Internal.InsertFunction.Context )
    , replaceFunction : List Install.Function.ReplaceFunction.Config
    , clauseInCase : List Install.ClauseInCase.Config
    , fieldInTypeAlias : List Install.FieldInTypeAlias.Config
    , initializer : List Install.Initializer.Config
    , initializerCmd : List Install.InitializerCmd.Config
    , subscription : List Install.Subscription.Config
    , customType : List ( Install.Type.Config, Install.Internal.Type.Context )
    , typeVariant : List Install.TypeVariant.Config
    }


{-| A transformation to apply.
-}
type Installation
    = AddImport Install.Import.Config
    | AddElementToList Install.ElementToList.Config
    | InsertFunction Install.Function.InsertFunction.Config
    | ReplaceFunction Install.Function.ReplaceFunction.Config
    | InsertClauseInCase Install.ClauseInCase.Config
    | FieldInTypeAlias Install.FieldInTypeAlias.Config
    | Initializer Install.Initializer.Config
    | InitializerCmd Install.InitializerCmd.Config
    | Subscription Install.Subscription.Config
    | AddType Install.Type.Config
    | AddTypeVariant Install.TypeVariant.Config


{-| Add an import, defined by [`Install.Import.config`](Install-Import#config).
-}
imports : Install.Import.Config -> Installation
imports =
    AddImport


{-| Add an element to the end of a list, defined by [`Install.ElementToList.config`](Install-ElementToList#config).
-}
elementToList : Install.ElementToList.Config -> Installation
elementToList =
    AddElementToList


{-| Insert a function, defined by [`Install.Function.InsertFunction.config`](Install-Function-InsertFunction#config).
-}
function : Install.Function.InsertFunction.Config -> Installation
function =
    InsertFunction


{-| Replace a function, defined by [`Install.Function.ReplaceFunction.config`](Install-Function-ReplaceFunction#config).
-}
replaceFunction : Install.Function.ReplaceFunction.Config -> Installation
replaceFunction =
    ReplaceFunction


{-| Insert a clause in a `case` expression, defined by [`Install.ClauseInCase.config`](Install-ClauseInCase#config).
-}
clauseInCase : Install.ClauseInCase.Config -> Installation
clauseInCase =
    InsertClauseInCase


{-| Insert a field in a type alias, defined by [`Install.FieldInTypeAlias.config`](Install-FieldInTypeAlias#config).
-}
fieldInTypeAlias : Install.FieldInTypeAlias.Config -> Installation
fieldInTypeAlias =
    FieldInTypeAlias


{-| Add fields to the body of a function like `init`, defined by [`Install.Initializer.config`](Install-Initializer#config).
-}
initializer : Install.Initializer.Config -> Installation
initializer =
    Initializer


{-| Add commands to the body of a function like `init`, defined by [`Install.InitializerCmd.config`](Install-InitializerCmd#config).
-}
initializerCmd : Install.InitializerCmd.Config -> Installation
initializerCmd =
    InitializerCmd


{-| Add subscriptions, defined by [`Install.Subscription.config`](Install-Subscription#config).
-}
subscription : Install.Subscription.Config -> Installation
subscription =
    Subscription


{-| Add a type, defined by [`Install.Type.config`](Install-Type#config).
-}
customType : Install.Type.Config -> Installation
customType =
    AddType


{-| Add a type variant, defined by [`Install.TypeVariant.config`](Install-TypeVariant#config).
-}
typeVariant : Install.TypeVariant.Config -> Installation
typeVariant =
    AddTypeVariant


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
                                { context | function = ( config, Install.Internal.InsertFunction.init ) :: context.function }

                            else
                                context

                        ReplaceFunction ((Install.Internal.ReplaceFunction.Config { hostModuleName }) as config) ->
                            if moduleName == hostModuleName then
                                { context | replaceFunction = config :: context.replaceFunction }

                            else
                                context

                        InsertClauseInCase ((Install.Internal.ClauseInCase.Config { hostModuleName }) as config) ->
                            if moduleName == hostModuleName then
                                { context | clauseInCase = config :: context.clauseInCase }

                            else
                                context

                        FieldInTypeAlias ((Install.Internal.FieldInTypeAlias.Config { hostModuleName }) as config) ->
                            if moduleName == hostModuleName then
                                { context | fieldInTypeAlias = config :: context.fieldInTypeAlias }

                            else
                                context

                        Initializer ((Install.Internal.Initializer.Config { hostModuleName }) as config) ->
                            if moduleName == hostModuleName then
                                { context | initializer = config :: context.initializer }

                            else
                                context

                        InitializerCmd ((Install.Internal.InitializerCmd.Config { hostModuleName }) as config) ->
                            if moduleName == hostModuleName then
                                { context | initializerCmd = config :: context.initializerCmd }

                            else
                                context

                        Subscription ((Install.Internal.Subscription.Config { hostModuleName }) as config) ->
                            if moduleName == hostModuleName then
                                { context | subscription = config :: context.subscription }

                            else
                                context

                        AddType ((Install.Internal.Type.Config { hostModuleName }) as config) ->
                            if moduleName == hostModuleName then
                                { context | customType = ( config, Install.Internal.Type.init ) :: context.customType }

                            else
                                context

                        AddTypeVariant ((Install.Internal.TypeVariant.Config { hostModuleName }) as config) ->
                            if moduleName == hostModuleName then
                                { context | typeVariant = config :: context.typeVariant }

                            else
                                context
                )
                { importContexts = []
                , elementToList = []
                , function = []
                , replaceFunction = []
                , clauseInCase = []
                , fieldInTypeAlias = []
                , initializer = []
                , initializerCmd = []
                , subscription = []
                , customType = []
                , typeVariant = []
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
        , customType =
            List.map
                (\( config, ctx ) -> ( config, Install.Internal.Type.importVisitor node ctx ))
                context.customType
      }
    )


declarationVisitor : Node Declaration -> Context -> ( List (Rule.Error {}), Context )
declarationVisitor node context =
    let
        errors : List (Error {})
        errors =
            List.concat
                [ List.concatMap
                    (\config -> Install.Internal.ElementToList.declarationVisitor config node)
                    context.elementToList
                , List.concatMap
                    (\config -> Install.Internal.ReplaceFunction.declarationVisitor config node)
                    context.replaceFunction
                , List.concatMap
                    (\config -> Install.Internal.ClauseInCase.declarationVisitor config node)
                    context.clauseInCase
                , List.concatMap
                    (\config -> Install.Internal.FieldInTypeAlias.declarationVisitor config node)
                    context.fieldInTypeAlias
                , List.concatMap
                    (\config -> Install.Internal.Initializer.declarationVisitor config node)
                    context.initializer
                , List.concatMap
                    (\config -> Install.Internal.InitializerCmd.declarationVisitor config node)
                    context.initializerCmd
                , List.concatMap
                    (\config -> Install.Internal.Subscription.declarationVisitor config node)
                    context.subscription
                , List.concatMap
                    (\config -> Install.Internal.TypeVariant.declarationVisitor config node)
                    context.typeVariant
                ]
    in
    ( errors
    , { context
        | function =
            List.map
                (\( config, ctx ) -> ( config, Install.Internal.InsertFunction.declarationVisitor config node ctx ))
                context.function
        , customType =
            List.map
                (\( config, ctx ) -> ( config, Install.Internal.Type.declarationVisitor config node ctx ))
                context.customType
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
            context.function
        , List.concatMap
            (\( config, ctx ) -> Install.Internal.Type.finalEvaluation config ctx)
            context.customType
        ]
