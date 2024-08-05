module Install.TypeVariantTest exposing (all)

import Install
import Install.TypeVariant
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.TypeVariant"
        [ Run.testFix_ test1
        , Run.testFix_ test2
        ]


test1 =
    { description = "should report an error when the variant does not exist"
    , src = src1
    , installation = rule1
    , under = under1
    , fixed = fixed1
    , message = "Add variants [Admin, Assistant] to Role"
    }


test2 =
    { description = "should report an error when the variant does not exist in nested module"
    , src = src2
    , installation = rule2
    , under = under2
    , fixed = fixed2
    , message = "Add variants [TO] to BrazilianStates"
    }


rule1 =
    Install.TypeVariant.config "User" "Role" [ "Admin", "Assistant Int" ]
        |> Install.addTypeVariant


src1 =
    """module User exposing (..)
type Role
   = Standard
"""


under1 =
    """type Role
   = Standard"""


fixed1 =
    """module User exposing (..)
type Role
   = Standard
    | Admin
    | Assistant Int
"""


rule2 =
    Install.TypeVariant.config "Data.States" "BrazilianStates" [ "TO" ]
        |> Install.addTypeVariant


src2 =
    """module Data.States exposing (..)

type BrazilianStates
    = AC
    | AL
    | AP
    | AM
    | BA
    | CE
    | DF
    | ES
    | GO
    | MA
    | MT
    | MS
    | MG
    | PA
    | PB
    | PR
    | PE
    | PI
    | RJ
    | RN
    | RS
    | RO
    | RR
    | SC
    | SP
    | SE
"""


under2 =
    """type BrazilianStates
    = AC
    | AL
    | AP
    | AM
    | BA
    | CE
    | DF
    | ES
    | GO
    | MA
    | MT
    | MS
    | MG
    | PA
    | PB
    | PR
    | PE
    | PI
    | RJ
    | RN
    | RS
    | RO
    | RR
    | SC
    | SP
    | SE"""


fixed2 =
    """module Data.States exposing (..)

type BrazilianStates
    = AC
    | AL
    | AP
    | AM
    | BA
    | CE
    | DF
    | ES
    | GO
    | MA
    | MT
    | MS
    | MG
    | PA
    | PB
    | PR
    | PE
    | PI
    | RJ
    | RN
    | RS
    | RO
    | RR
    | SC
    | SP
    | SE
    | TO
"""
