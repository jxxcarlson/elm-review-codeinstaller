module Install.Type exposing (config, Config)

{-| `Install.Type` provides a rule that checks if a type is present
in the given module and if not, it adds it right after the imports.

For example, the rule

    Install.Type.config "Frontend" "Magic" [ "Inactive", "Wizard String", "Spell String Int" ]
        |> Install.customType

results in insertion the text below in the module "Frontend":

    type Magic
        = Inactive
        | Wizard String
        | Spell String Int

@docs config, Config

-}

import Install.Internal.Type as Internal


{-| Configuration for rule.
-}
type alias Config =
    Internal.Config


{-| Rule to add a type to a module if it is not present
-}
config : String -> String -> List String -> Config
config hostModuleName typeName variants =
    Internal.Config
        { hostModuleName = String.split "." hostModuleName
        , typeName = typeName
        , variants = variants
        }



--moduleDefinitionVisitor : Node Module -> Context -> ( List (Error {}), Context )
--moduleDefinitionVisitor def context =
--    -- visit the module definition to set the module definition as the lastNodeRange in case the module has no types yet TODO: ??
--    ( [], { context | lastNodeRange = Node.range def } )
