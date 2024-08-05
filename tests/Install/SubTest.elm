module Install.SubTest exposing (..)

import Install
import Install.Subscription
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.Initializer"
        [ Run.testFix_ test1
        , Run.expectNoErrorsTest_ test2.description test2.src test2.installation
        , Run.testFix_ test3
        ]


test1 =
    { description = "should add to subscriptions"
    , src = """module Backend exposing (..)

subscriptions model =
  Sub.batch [ foo model ]
"""
    , installation =
        Install.Subscription.config "Backend" [ "bar model" ]
            |> Install.subscription
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
    , installation =
        Install.Subscription.config "Backend" [ "bar model" ]
            |> Install.subscription
    }



-- test3 - should add multiple items


test3 =
    { description = "should add multiple items to subscriptions"
    , src = """module Backend exposing (..)

subscriptions model =
  Sub.batch [ foo model ]
"""
    , installation =
        Install.Subscription.config "Backend" [ "bar model", "baz model" ]
            |> Install.subscription
    , under = """subscriptions"""
    , fixed = """module Backend exposing (..)

subscriptions model =
  Sub.batch [ foo model, bar model, baz model ]
"""
    , message = "Add to subscriptions: , bar model, baz model"
    }
