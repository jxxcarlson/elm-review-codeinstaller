module Install.InitializerCmdTest exposing (all)

import Install.InitializerCmd
import Run
import Test exposing (Test, describe)


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
    , rule = Install.InitializerCmd.makeRule "Client" "init" [ "Task.perform GotFastTick", "Helper.getAtmosphericRandomNumbers" ]
    , under = """init =
    ( { age = 30
      }
    , Cmd.none
    )"""
    , fixed = """module Client exposing (..)
init : (Model, Cmd Msg)
init =
    ( { age = 30
      }
    , Cmd.batch [ Task.perform GotFastTick, Helper.getAtmosphericRandomNumbers ]
    )
"""
    , message = "Add cmds Task.perform GotFastTick, Helper.getAtmosphericRandomNumbers to the model"
    }



--Cmd.batch
--        [ Time.now |> Task.perform GotFastTick
--        , Helper.getAtmosphericRandomNumbers
--        ]
