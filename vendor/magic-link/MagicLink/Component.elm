module MagicLink.Component exposing (Component)


type alias Component context state msg effect view =
    { init : context -> ( state, Cmd msg )
    , update : context -> msg -> state -> ( state, Cmd msg, Maybe effect )
    , newContext : Maybe (context -> msg)
    , subscriptions : context -> state -> Sub msg
    , view : context -> state -> view
    , defaultContext : context
    , demoUpdate : effect -> context -> context
    }
