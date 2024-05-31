module Install.TypeVariantTest exposing (all)

import Install.TypeVariant
import Review.Rule exposing (Rule)
import Review.Test
import Run
import Test exposing (Test, describe, test)


all : Test
all =
    describe "Install.TypeVariant"
        [ Run.testFix test1
        ]


test1 =
    { description = "should report an error when the variant does not exist"
    , src = src1
    , rule = rule1
    , under = under1
    , fixed = fixed1
    , message = "Add Admin to Role"
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
