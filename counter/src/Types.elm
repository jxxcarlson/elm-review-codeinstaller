module Types exposing (..)

import Lamdera exposing (ClientId, SessionId)
import Set exposing (Set)


type alias BackendModel =
    { counter : Int
    }


type alias FrontendModel =
    { counter : Int
    , clientId : String
    }


type FrontendMsg
    = Increment
    | Decrement
    | FNoop
    | Reset


type ToBackend
    = CounterIncremented
    | CounterDecremented
    | CounterReset


type BackendMsg
    = ClientConnected SessionId ClientId
    | Noop


type ToFrontend
    = CounterNewValue Int String
