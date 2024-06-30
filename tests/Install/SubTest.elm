module Install.SubTest exposing (..)

import Install.Subscription
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.Initializer"
        [ Run.testFix test1 ]


test1 =
    { description = "should not report an error when the item already is in the Sub.batch list"
    , src = """module Backend exposing (..)

subscriptions model =
  Sub.batch [ foo model ]
"""
    , rule = Install.Subscription.makeRule "Backend" "bar model"
    , under = """subscriptions"""
    , fixed = """module Backend exposing (..)

subscriptions model =
  Sub.batch [ foo model, bar model ]
"""
    , message = "Add to subscriptions: , bar model"
    }
