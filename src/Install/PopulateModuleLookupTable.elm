module Install.PopulateModuleLookupTable exposing (..)

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
