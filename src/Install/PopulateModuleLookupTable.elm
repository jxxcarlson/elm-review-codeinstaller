module Install.PopulateModuleLookupTable exposing (..)

import Review.ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule


fromProjectToModule : Rule.ContextCreator from { moduleNameLookupTable : ModuleNameLookupTable, moduleName : String }
fromProjectToModule =
    Rule.initContextCreator
        (\moduleNameLookupTable moduleName _ ->
            { moduleNameLookupTable = moduleNameLookupTable
            , moduleName = String.join "." moduleName
            }
        )
        |> Rule.withModuleNameLookupTable
        |> Rule.withModuleName
