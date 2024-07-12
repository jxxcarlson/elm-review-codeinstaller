module MagicLink.Auth exposing
    ( backendConfig
    , update
    , updateFromBackend
    )

import Auth.Common exposing (UserInfo)
import Auth.Flow
import Auth.Method.EmailMagicLink
import Dict exposing (Dict)
import Dict.Extra as Dict
import EmailAddress
import Lamdera exposing (ClientId, SessionId)
import MagicLink.Backend
import MagicLink.Common
import MagicLink.Frontend
import MagicLink.Helper as Helper
import MagicLink.Types
import Route
import Time
import Types exposing (BackendModel, BackendMsg(..), FrontendMsg(..), ToBackend(..), ToFrontend(..))
import Url
import User


update : MagicLink.Types.Msg -> MagicLink.Types.Model -> ( MagicLink.Types.Model, Cmd FrontendMsg )
update msg model =
    case msg of
        MagicLink.Types.SubmitEmailForSignIn ->
            MagicLink.Frontend.submitEmailForSignin model

        MagicLink.Types.AuthSigninRequested { methodId, email } ->
            Auth.Flow.signInRequested methodId model email
                |> Tuple.mapSecond (AuthToBackend >> Lamdera.sendToBackend)

        MagicLink.Types.ReceivedSigninCode loginCode ->
            MagicLink.Frontend.signInWithCode model loginCode

        --MagicLink.Types.CancelSignIn ->
        --    ( { model | signInStatus = MagicLink.Types.NotSignedIn }, Helper.trigger (Types.SetRoute_ Route.HomepageRoute) )
        MagicLink.Types.CancelSignUp ->
            ( { model | signInStatus = MagicLink.Types.NotSignedIn }, Cmd.none )

        MagicLink.Types.OpenSignUp ->
            ( { model | signInStatus = MagicLink.Types.SigningUp }, Cmd.none )

        MagicLink.Types.TypedEmailInSignInForm email ->
            MagicLink.Frontend.enterEmail model email

        --MagicLink.Types.SubmitSignUp ->
        --    MagicLink.Frontend.submitSignUp model
        --
        --MagicLink.Types.SignOut ->
        --    MagicLink.Frontend.signOut model
        MagicLink.Types.InputRealname str ->
            ( { model | realname = str }, Cmd.none )

        MagicLink.Types.InputUsername str ->
            ( { model | username = str }, Cmd.none )

        MagicLink.Types.InputEmail str ->
            ( { model | email = str }, Cmd.none )

        MagicLink.Types.SetRoute route ->
            ( model, Helper.trigger <| AuthFrontendMsg <| MagicLink.Types.SetRoute route )


updateFromBackend :
    Auth.Common.ToFrontend
    -> MagicLink.Types.Model
    -> ( MagicLink.Types.Model, Cmd FrontendMsg )
updateFromBackend authToFrontendMsg model =
    case authToFrontendMsg of
        Auth.Common.ReceivedMessage result ->
            case result of
                Ok message ->
                    ( { model | message = message }, Cmd.none )

                Err b ->
                    ( { model | message = "Error: " ++ b }, Cmd.none )

        Auth.Common.AuthInitiateSignin url ->
            Auth.Flow.startProviderSignin url model

        Auth.Common.AuthError err ->
            Auth.Flow.setError model err

        Auth.Common.AuthSessionChallenge _ ->
            ( model, Cmd.none )

        Auth.Common.AuthSignInWithTokenResponse result ->
            case result of
                Ok userData ->
                    ( { model
                        | currentUserData = Just userData
                        , authFlow =
                            Auth.Common.Done
                                { email = userData.email
                                , name = Just userData.name
                                , username = Just userData.username
                                }

                        -- TODO, disable as test:, signInStatus = MagicLink.Types.SignedIn
                      }
                    , Cmd.none
                    )

                --|> MagicLink.Frontend.signInWithTokenResponseM userData
                -- |> (\( m, c ) -> ( m, Cmd.batch [ c, MagicLink.Frontend.signInWithTokenResponseC userData, Helper.trigger <| SetRoute_ Route.HomepageRoute ] ))
                Err _ ->
                    ( model, Cmd.none )


config : Auth.Common.Config FrontendMsg ToBackend BackendMsg ToFrontend MagicLink.Types.Model BackendModel
config =
    { toBackend = AuthToBackend
    , toFrontend = AuthToFrontend
    , backendMsg = AuthBackendMsg
    , sendToFrontend = Lamdera.sendToFrontend
    , sendToBackend = Lamdera.sendToBackend
    , renewSession = renewSession
    , methods =
        [ Auth.Method.EmailMagicLink.configuration
            { initiateSignin = initiateEmailSignin
            , onAuthCallbackReceived = onEmailAuthCallbackReceived
            }
        ]
    }


initiateEmailSignin : SessionId -> ClientId -> BackendModel -> { a | username : Maybe String } -> Time.Posix -> ( BackendModel, Cmd BackendMsg )
initiateEmailSignin sessionId clientId model login now =
    case login.username of
        Nothing ->
            ( model, MagicLink.Common.sendMessage clientId "No username provided." )

        Just emailString ->
            case EmailAddress.fromString emailString of
                Nothing ->
                    ( model, MagicLink.Common.sendMessage clientId "Invalid email address." )

                Just emailAddress_ ->
                    case model.users |> Dict.get emailString of
                        Just user ->
                            let
                                ( newModel, loginToken ) =
                                    MagicLink.Backend.getLoginCode now model

                                loginCode =
                                    loginToken |> Result.withDefault 31462718

                                -- TODO ^^ bad code!
                            in
                            ( { newModel
                                | pendingEmailAuths =
                                    model.pendingEmailAuths
                                        |> Dict.insert sessionId
                                            { created = now
                                            , sessionId = sessionId
                                            , username = user.username
                                            , fullname = user.fullname
                                            , token = loginCode |> String.fromInt
                                            }
                              }
                            , Cmd.batch
                                [ MagicLink.Backend.sendLoginEmail_ (Auth.Common.AuthSentLoginEmail now emailAddress_ >> AuthBackendMsg) emailAddress_ loginCode
                                , MagicLink.Common.sendMessage clientId
                                    ("We have sent you a login email at " ++ EmailAddress.toString emailAddress_)
                                ]
                            )

                        Nothing ->
                            ( model, MagicLink.Common.sendMessage clientId "You are not properly registered." )


onEmailAuthCallbackReceived :
    Auth.Common.SessionId
    -> Auth.Common.ClientId
    -> Url.Url
    -> Auth.Common.AuthCode
    -> Auth.Common.State
    -> Time.Posix
    -> (Auth.Common.BackendMsg -> BackendMsg)
    -> BackendModel
    -> ( BackendModel, Cmd BackendMsg )
onEmailAuthCallbackReceived sessionId clientId receivedUrl code state now asBackendMsg backendModel =
    case backendModel.pendingEmailAuths |> Dict.find (\k p -> p.token == code) of
        Just ( sessionIdRequester, pendingAuth ) ->
            { backendModel | pendingEmailAuths = backendModel.pendingEmailAuths |> Dict.remove sessionIdRequester }
                |> findOrRegisterUser
                    { currentClientId = clientId
                    , requestingSessionId = pendingAuth.sessionId
                    , username = pendingAuth.username
                    , fullname = pendingAuth.fullname
                    , authTokenM = Nothing
                    , now = pendingAuth.created
                    }

        Nothing ->
            ( backendModel
            , Lamdera.sendToFrontend sessionId
                (AuthToFrontend <| Auth.Common.AuthSessionChallenge Auth.Common.AuthSessionMissing)
            )


findOrRegisterUser :
    { currentClientId : Lamdera.ClientId
    , requestingSessionId : Lamdera.SessionId
    , username : String -- TODO: alias this
    , fullname : String -- TODO: alias this
    , authTokenM : Maybe Auth.Common.Token
    , now : Time.Posix
    }
    -> BackendModel
    -> ( BackendModel, Cmd BackendMsg )
findOrRegisterUser params model =
    -- TODO : real implementation needed here
    ( model, Cmd.none )


backendConfig : BackendModel -> Auth.Flow.BackendUpdateConfig FrontendMsg BackendMsg ToFrontend MagicLink.Types.Model BackendModel
backendConfig model =
    { asToFrontend = AuthToFrontend
    , asBackendMsg = AuthBackendMsg
    , sendToFrontend = Lamdera.sendToFrontend
    , backendModel = model
    , loadMethod = Auth.Flow.methodLoader config.methods
    , handleAuthSuccess = handleAuthSuccess model
    , isDev = True
    , renewSession = renewSession
    , logout = logout
    }


logout : SessionId -> ClientId -> BackendModel -> ( BackendModel, Cmd msg )
logout sessionId _ model =
    ( { model | sessions = model.sessions |> Dict.remove sessionId }, Cmd.none )


renewSession : Lamdera.SessionId -> Lamdera.ClientId -> BackendModel -> ( BackendModel, Cmd BackendMsg )
renewSession _ _ model =
    ( model, Cmd.none )


handleAuthSuccess :
    BackendModel
    -> SessionId
    -> ClientId
    -> Auth.Common.UserInfo
    -> Auth.Common.MethodId
    -> Maybe Auth.Common.Token
    -> Time.Posix
    -> ( BackendModel, Cmd BackendMsg )
handleAuthSuccess backendModel sessionId clientId userInfo _ _ _ =
    -- TODO handle renewing sessions if that is something you need
    let
        sessionsWithOutThisOne : Dict SessionId UserInfo
        sessionsWithOutThisOne =
            Dict.removeWhen (\_ { email } -> email == userInfo.email) backendModel.sessions

        newSessions =
            Dict.insert sessionId userInfo sessionsWithOutThisOne
    in
    ( { backendModel | sessions = newSessions }
    , Cmd.batch
        [ -- renewSession_ user_.id sessionId clientId
          Lamdera.sendToFrontend clientId (AuthSuccess userInfo)
        ]
    )
