module Install.InitializerTest exposing (all)

import Install.Initializer
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.Initializer"
        [ Run.testFix test1, Run.testFix test2 ]


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
    , rule = Install.Initializer.makeRule "Client" "init" [ { field = "name", value = "\"Nancy\"" } ]
    , under = """init =
    ( { age = 30
      }
    , Cmd.none
    )"""
    , fixed = """module Client exposing (..)
init : (Model, Cmd Msg)
init =
    ( { age = 30
      , name = "Nancy"
      }
    , Cmd.none
    )
"""
    , message = "Add fields to the model"
    }


test2 =
    { description = "should insert multiple fields"
    , src = """module Client exposing (..)
init : (Model, Cmd Msg)
init =
    ( { age = 30
      }
    , Cmd.none
    )
"""
    , rule = Install.Initializer.makeRule "Client" "init" [ { field = "name", value = "\"Nancy\"" }, { field = "count", value = "0" } ]
    , under = """init =
    ( { age = 30
      }
    , Cmd.none
    )"""
    , fixed = """module Client exposing (..)
init : (Model, Cmd Msg)
init =
    ( { age = 30
      , name = "Nancy"
      , count = 0
      }
    , Cmd.none
    )
"""
    , message = "Add fields to the model"
    }
