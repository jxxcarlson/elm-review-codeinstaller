module Install.TypeVariantTest exposing (..)

import Install.TypeVariant
import Review.Test
import Test exposing (Test, describe, test)


all : Test
all =
    let
        rule =
            Install.TypeVariant.makeRule "User" "Role" "Admin"
    in
    describe "Install.TypeVariant"
        [ test "should not report an error when the variant already exists" <|
            \() ->
                """module User exposing (..)
type Role
    = Standard
    | Admin
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "should report an error when the variant does not exist" <|
            \() ->
                """module User exposing (..)
type Role
    = Standard
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error { message = "Add Admin to Role", details = [ "" ], under = """type Role
    = Standard""" }
                            |> Review.Test.whenFixed """module User exposing (..)
type Role
    = Standard
    | Admin
"""
                        ]
        ]
