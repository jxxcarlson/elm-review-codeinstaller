module Install.Function.InsertFunction exposing
    ( insert
    , Config, withInsertAfter
    )

{-| Add a function in a given module if it is not present.

    -- code for ReviewConfig.elm:
    rule =
        Install.Function.InsertFunction.insert
            "Frontend"
            "view"
            """view model =
            Html.text "This is a test\""""
            |> Install.insertFunction

Running this rule will insert the function `view` in the module `Frontend` with the provided implementation.

The form of the rule is the same for nested modules:

    rule =
        Install.Function.InsertFunction.insert
            "Foo.Bar"
            "earnInterest"
            "hoho model = { model | interest = 1.03 * model.interest }"
            |> Install.insertFunction

@docs insert
@docs Config, withInsertAfter

-}

import Install.Internal.InsertFunction as Internal
import Install.Library


{-| Configuration for rule: add a function in a specified module if it does not already exist.
-}
type alias Config =
    Internal.Config


{-| Initialize the configuration for the rule.
-}
insert : String -> String -> String -> Config
insert hostModuleName functionName functionImplementation =
    Internal.Config
        { hostModuleName = String.split "." hostModuleName
        , functionName = functionName
        , functionImplementation = functionImplementation
        , theFunctionNodeExpression = Install.Library.maybeNodeExpressionFromString { moduleName = String.split "." hostModuleName } functionImplementation
        , insertAt = Internal.AtEnd
        }


{-| Add the function after a specified declaration. Just give the name of a function, type, type alias or port and the function will be added after that declaration. Only work if the function is being added and not replaced.
-}
withInsertAfter : String -> Config -> Config
withInsertAfter previousDeclaration (Internal.Config config_) =
    Internal.Config { config_ | insertAt = Internal.After previousDeclaration }
