module Install.InitializerTest exposing (all)

import Install.Initializer
import Review.Test
import Run
import Test exposing (Test, describe, test)


all : Test
all =
    describe "Install.Initializer"
        [ Run.testFix test1 ]


test1 =
    { description = "should not report an error when the field already exists"
    , src = """module Client exposing (..)
init : (Model, Cmd Msg)
init =
    ( { age = 30
      }
    , Cmd.none
    )
"""
    , rule = Install.Initializer.makeRule "Client" "init" "name" "\"Nancy\""
    , under = """init =
    ( { age = 30
      }
    , Cmd.none
    )"""
    , fixed = """module Client exposing (..)
init : (Model, Cmd Msg)
init =
    ( { age = 30, name = "Nancy"

      }
    , Cmd.none
    )
"""
    , message = "Add field name with value \"Nancy\" to the model"
    }
