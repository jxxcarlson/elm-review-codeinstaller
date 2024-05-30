module Install.InitializerTest exposing (..)

import Install.Initializer
import Review.Test
import Test exposing (Test, describe, test)


all : Test
all =
    let
        rule =
            Install.Initializer.makeRule "Client" "init" "name" "\"Nancy\""
    in
    describe "Install.Initializer"
        [ test "should not report an error when the field already exists" <|
            \() ->
                """module Client exposing (..)
init : (Model, Cmd Msg)
init =
    ( { age = 30
    , name = "Nancy"
      }
    , Cmd.none
    )
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "should report an error and fix it when the field does not exist" <|
            \() ->
                """module Client exposing (..)
init : (Model, Cmd Msg)
init =
    ( { age = 30
      }
    , Cmd.none
    )
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error { message = "Add field name with value \"Nancy\" to the model", details = [ "" ], under = """init =
    ( { age = 30
      }
    , Cmd.none
    )""" }
                            |> Review.Test.whenFixed """module Client exposing (..)
init : (Model, Cmd Msg)
init =
    ( { age = 30, name = "Nancy"

      }
    , Cmd.none
    )
"""
                        ]
        ]
