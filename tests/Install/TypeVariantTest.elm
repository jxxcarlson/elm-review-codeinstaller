module Install.TypeVariantTest exposing (all)

import Install.TypeVariant
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.TypeVariant"
        [ Run.testFix test1
        , Run.testFix test2
        ]


test1 =
    { description = "should report an error when the variant does not exist"
    , src = src1
    , rule = rule1
    , under = under1
    , fixed = fixed1
    , message = "Add Admin to Role"
    }


test2 =
    { description = "should report an error when the variant does not exist in nested module"
    , src = src2
    , rule = rule2
    , under = under2
    , fixed = fixed2
    , message = "Add TO to BrazilianStates"
    }


rule1 =
    Install.TypeVariant.makeRule "User" "Role" "Admin"


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
"""


rule2 =
    Install.TypeVariant.makeRule "Data.States" "BrazilianStates" "TO"


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
