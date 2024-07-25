module Install.InitializerCmdTest exposing (all)

import Install
import Install.InitializerCmd
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.Initializer"
        [ Run.testFix_ test1
        , Run.expectNoErrorsTest_ test2.description test2.src test2.installation
        ]


test1 =
    { description = "should insert multiple fields"
    , src = """module Client exposing (..)
init : (Model, Cmd Msg)
init =
    ( { age = 30
      }
    , Cmd.none
    )
"""
    , installation =
        Install.InitializerCmd.config "Client" "init" [ "Task.perform GotFastTick", "Helper.getAtmosphericRandomNumbers" ]
            |> Install.initializerCmd
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



-- test2 - should not report error when the field already exists


test2 =
    { description = "should not report an error when the field already exists"
    , src = test1.fixed
    , installation =
        Install.InitializerCmd.config "Client" "init" [ "Task.perform GotFastTick", "Helper.getAtmosphericRandomNumbers" ]
            |> Install.initializerCmd
    }



--Cmd.batch
--        [ Time.now |> Task.perform GotFastTick
--        , Helper.getAtmosphericRandomNumbers
--        ]
