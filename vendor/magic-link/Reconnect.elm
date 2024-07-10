module Reconnect exposing (connect, reconnect)

import AssocList
import Auth.Common
import Dict exposing (Dict)
import Lamdera exposing (..)
import MagicLink.Helper
import Process
import Task
import Types
import User


reconnect model sessionId clientId =
    let
        userInfo : Maybe Auth.Common.UserInfo
        userInfo =
            Dict.get sessionId model.sessions

        maybeUser =
            case Maybe.map .username userInfo of
                Just mu ->
                    case mu of
                        Just username ->
                            Dict.get username model.users

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing
    in
    Lamdera.sendToFrontend clientId (Types.UserSignedIn maybeUser)


connect : Types.BackendModel -> SessionId -> ClientId -> Cmd Types.BackendMsg
connect model sessionId clientId =
    Cmd.batch
        [ MagicLink.Helper.getAtmosphericRandomNumbers
        , reconnect model sessionId clientId
        , case AssocList.get sessionId model.sessionDict of
            Just username ->
                case Dict.get username model.users of
                    Just user ->
                        Process.sleep 60 |> Task.perform (always (Types.AutoLogin sessionId (User.signinDataOfUser user)))

                    Nothing ->
                        Lamdera.sendToFrontend clientId (Types.AuthToFrontend <| Auth.Common.AuthSignInWithTokenResponse (Err 0))

            Nothing ->
                Lamdera.sendToFrontend clientId (Types.AuthToFrontend <| Auth.Common.AuthSignInWithTokenResponse (Err 1))
        ]
