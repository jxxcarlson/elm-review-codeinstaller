module Install.InitializerTest exposing (all)

import Install.Initializer
import Run
import Test exposing (Test, describe)


all : Test
all =
    describe "Install.Initializer"
        [ Run.testFix test1
        , Run.testFix test2
        , Run.testFix test3
        , Run.testFix test4
        ]


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
    ( { age = 30, name = "Nancy"
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
    ( { age = 30, name = "Nancy", count = 0
      }
    , Cmd.none
    )
"""
    , message = "Add fields to the model"
    }


test3 =
    { description = "should insert a field in a function with multiple arguments"
    , src = src3
    , rule = rule3
    , under = under3
    , fixed = fixed3
    , message = "Add fields to the model"
    }


src3 =
    """module Frontend exposing (app)

import Browser
import Browser.Dom
import Browser.Events
import Browser.Navigation
import Json.Decode
import Lamdera exposing (sendToBackend)
import Route
import Task
import Time
import Types exposing (..)
import Url
import View.Main


{-| Lamdera applications define 'app' instead of 'main'.

Lamdera.frontend is the same as Browser.application with the
additional update function; updateFromBackend.

-}
app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = subscriptions
        , view = View.Main.view
        }


subscriptions : FrontendModel -> Sub FrontendMsg
subscriptions _ =
    Sub.batch
        [ Browser.Events.onResize GotWindowSize
        , Browser.Events.onMouseUp (Json.Decode.succeed MouseDown)
        , Time.every 1000 Tick
        ]


init : Url.Url -> Browser.Navigation.Key -> ( FrontendModel, Cmd FrontendMsg )
init url key =
    let
        route =
            Route.decode url
    in
    ( Loading
        { key = key
        , initUrl = url
        , now = Time.millisToPosix 0
        , window = Nothing
        , route = route
        }
    , Cmd.batch
        [ Browser.Dom.getViewport
            |> Task.perform (\\{ viewport } -> GotWindowSize (round viewport.width) (round viewport.height))
        ]
    )"""


rule3 =
    Install.Initializer.makeRule "Frontend" "init" [ { field = "authFlow", value = "Auth.Common.Idle" } ]


fixed3 =
    """module Frontend exposing (app)

import Browser
import Browser.Dom
import Browser.Events
import Browser.Navigation
import Json.Decode
import Lamdera exposing (sendToBackend)
import Route
import Task
import Time
import Types exposing (..)
import Url
import View.Main


{-| Lamdera applications define 'app' instead of 'main'.

Lamdera.frontend is the same as Browser.application with the
additional update function; updateFromBackend.

-}
app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = subscriptions
        , view = View.Main.view
        }


subscriptions : FrontendModel -> Sub FrontendMsg
subscriptions _ =
    Sub.batch
        [ Browser.Events.onResize GotWindowSize
        , Browser.Events.onMouseUp (Json.Decode.succeed MouseDown)
        , Time.every 1000 Tick
        ]


init : Url.Url -> Browser.Navigation.Key -> ( FrontendModel, Cmd FrontendMsg )
init url key =
    let
        route =
            Route.decode url
    in
    ( Loading
        { key = key
        , initUrl = url
        , now = Time.millisToPosix 0
        , window = Nothing
        , route = route, authFlow = Auth.Common.Idle
        }
    , Cmd.batch
        [ Browser.Dom.getViewport
            |> Task.perform (\\{ viewport } -> GotWindowSize (round viewport.width) (round viewport.height))
        ]
    )"""


under3 =
    """init url key =
    let
        route =
            Route.decode url
    in
    ( Loading
        { key = key
        , initUrl = url
        , now = Time.millisToPosix 0
        , window = Nothing
        , route = route
        }
    , Cmd.batch
        [ Browser.Dom.getViewport
            |> Task.perform (\\{ viewport } -> GotWindowSize (round viewport.width) (round viewport.height))
        ]
    )"""


test4 =
    { description = "should insert multiple fields in a function with multiple arguments"
    , src = src4
    , rule = rule4
    , under = under4
    , fixed = fixed4
    , message = "Add fields to the model"
    }


rule4 =
    Install.Initializer.makeRule "Backend"
        "init"
        [ { field = "pendingAuths", value = "Dict.empty" }
        , { field = "sessions", value = "Dict.empty" }
        , { field = "users", value = "Dict.empty" }
        ]


src4 =
    """module Backend exposing (app, init)

init : ( BackendModel, Cmd BackendMsg )
init =
    ( { counter = 0
      }
    , Cmd.none
    )"""


under4 =
    """init =
    ( { counter = 0
      }
    , Cmd.none
    )"""


fixed4 =
    """module Backend exposing (app, init)

init : ( BackendModel, Cmd BackendMsg )
init =
    ( { counter = 0, pendingAuths = Dict.empty, sessions = Dict.empty, users = Dict.empty
      }
    , Cmd.none
    )"""
