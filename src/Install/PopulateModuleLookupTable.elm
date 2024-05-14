module Install.PopulateModuleLookupTable exposing (..)

import Dict
import Elm.Syntax.Declaration
import Elm.Syntax.Node exposing (Node)
import Review.ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule


fromProjectToModule : Rule.ContextCreator ProjectContext ModuleContext
fromProjectToModule =
    Rule.initContextCreator
        (\moduleNameLookupTable moduleName _ ->
            { moduleNameLookupTable = moduleNameLookupTable
            , moduleName = String.join "." moduleName
            }
        )
        |> Rule.withModuleNameLookupTable
        |> Rule.withModuleName
