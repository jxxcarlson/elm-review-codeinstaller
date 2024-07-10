module Session exposing (Interaction(..), SessionInfo)

import Auth.Common
import Dict
import Lamdera exposing (SessionId)
import Time


type alias SessionInfo =
    Dict.Dict SessionId Interaction


type Interaction
    = ISignIn Time.Posix
    | ISignOut Time.Posix
    | ISignUp Time.Posix



-- reconnect : Types.BackendModel -> Lamdera.SessionId -> Lamdera.ClientId -> Cmd backendMsg
