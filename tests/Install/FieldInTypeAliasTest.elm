module Install.FieldInTypeAliasTest exposing (..)

import Install.FieldInTypeAlias
import Review.Test
import Test exposing (Test, describe, test)


all : Test
all =
    let
        rule =
            Install.FieldInTypeAlias.makeRule "Client" "Client" "name : String"
    in
    describe "Install.FieldInTypeAlias"
        [ test "should not report an error when the field already exists" <|
            \() ->
                """module Client exposing (..)
type alias Client =
    { name : String
    , age : Int
    }
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "should report an error when the field does not exist" <|
            \() ->
                """module Client exposing (..)
type alias Client =
    { age : Int
    }
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error { message = "Add name to Client", details = [ "" ], under = """type alias Client =
    { age : Int
    }""" }
                            |> Review.Test.whenFixed """module Client exposing (..)
type alias Client =
    { age : Int
    , name : String
    }
"""
                        ]
        ]
