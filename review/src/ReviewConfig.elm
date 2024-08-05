module ReviewConfig exposing (config)

import Docs.NoMissing exposing (exposedModules, onlyExposed)
import Docs.ReviewAtDocs
import Docs.ReviewLinksAndSections
import Docs.UpToDateReadmeLinks
import NoDebug.Log
import NoDebug.TodoOrToString
import NoMissingTypeExpose
import NoPrematureLetComputation
import NoUnused.Dependencies
import NoUnused.Variables
import Review.Rule exposing (Rule)
import Simplify


config : List Rule
config =
    [ NoUnused.Variables.rule
    , Docs.NoMissing.rule
        { document = onlyExposed
        , from = exposedModules
        }
    , Docs.ReviewLinksAndSections.rule
    , Docs.ReviewAtDocs.rule
    , NoMissingTypeExpose.rule
    , NoPrematureLetComputation.rule
    , Simplify.rule Simplify.defaults
    ]
