module Install.SubTest exposing (..)

import Install.Subscription
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.Initializer"
        [ Run.testFix test1
        , Run.expectNoErrorsTest test2.description test2.src test2.rule
        , Run.testFix test3
        ]


test1 =
    { description = "should add to subscriptions"
    , src = """module Backend exposing (..)

subscriptions model =
  Sub.batch [ foo model ]
"""
    , rule = Install.Subscription.makeRule "Backend" [ "bar model" ]
    , under = """subscriptions"""
    , fixed = """module Backend exposing (..)

subscriptions model =
  Sub.batch [ foo model, bar model ]
"""
    , message = "Add to subscriptions: , bar model"
    }


test2 =
    { description = "should not report an error if the item is already in the list"
    , src = """module Backend exposing (..)

subscriptions model =
  Sub.batch [ foo model, bar model ]
"""
    , rule = Install.Subscription.makeRule "Backend" [ "bar model" ]
    }



-- test3 - should add multiple items


test3 =
    { description = "should add multiple items to subscriptions"
    , src = """module Backend exposing (..)

subscriptions model =
  Sub.batch [ foo model ]
"""
    , rule = Install.Subscription.makeRule "Backend" [ "bar model", "baz model" ]
    , under = """subscriptions"""
    , fixed = """module Backend exposing (..)

subscriptions model =
  Sub.batch [ foo model, bar model, baz model ]
"""
    , message = "Add to subscriptions: , bar model, baz model"
    }
