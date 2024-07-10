module MagicLink.Backend exposing
    ( addUser
    , checkLogin
    , getLoginCode
    , requestSignUp
    , sendLoginEmail_
    , signInWithMagicToken
    )

import AssocList
import Auth.Common
import Config
import Dict
import Duration
import Email.Html
import Email.Html.Attributes
import EmailAddress exposing (EmailAddress)
import Hex
import Http
import Id exposing (Id)
import Lamdera exposing (ClientId, SessionId)
import List.Extra
import List.Nonempty
import LocalUUID
import MagicLink.LoginForm
import Postmark
import Quantity
import Sha256
import String.Nonempty exposing (NonemptyString)
import Time
import Types exposing (BackendModel, BackendMsg, ToFrontend(..))
import User


addUser : BackendModel -> ClientId -> String -> String -> String -> ( BackendModel, Cmd BackendMsg )
addUser model clientId email realname username =
    case EmailAddress.fromString email of
        Nothing ->
            ( model, Lamdera.sendToFrontend clientId (SignInError <| "Invalid email: " ++ email) )

        Just validEmail ->
            addUser1 model clientId email validEmail realname username


checkLogin : BackendModel -> ClientId -> SessionId -> ( BackendModel, Cmd BackendMsg )
checkLogin model clientId sessionId =
    ( model
    , if Dict.isEmpty model.users then
        Cmd.batch
            [ Err Types.Sunny |> CheckSignInResponse |> Lamdera.sendToFrontend clientId
            ]

      else
        case getUserFromSessionId sessionId model of
            Just ( userId, user ) ->
                getLoginData userId user model
                    |> CheckSignInResponse
                    |> Lamdera.sendToFrontend clientId

            Nothing ->
                CheckSignInResponse (Err Types.LoadedBackendData) |> Lamdera.sendToFrontend clientId
    )


{-|

    Use magicToken, an Int, to sign in a user.

-}
signInWithMagicToken :
    Time.Posix
    -> SessionId
    -> ClientId
    -> Int
    -> BackendModel
    -> ( BackendModel, Cmd BackendMsg )
signInWithMagicToken time sessionId clientId magicToken model =
    case Dict.get sessionId model.pendingEmailAuths of
        Just pendingAuth ->
            handleExistingSession model pendingAuth.username sessionId clientId magicToken

        Nothing ->
            handleNoSession model time sessionId clientId magicToken


requestSignUp : BackendModel -> ClientId -> String -> String -> String -> ( BackendModel, Cmd BackendMsg )
requestSignUp model clientId fullname username email =
    case model.localUuidData of
        Nothing ->
            ( model, Lamdera.sendToFrontend clientId (UserSignedIn Nothing) )

        -- TODO, need to signal & handle error
        Just uuidData ->
            case EmailAddress.fromString email of
                Nothing ->
                    ( model, Lamdera.sendToFrontend clientId (UserSignedIn Nothing) )

                Just validEmail ->
                    let
                        user =
                            { fullname = fullname
                            , username = username
                            , email = validEmail
                            , emailString = email
                            , created_at = model.time
                            , updated_at = model.time
                            , id = LocalUUID.extractUUIDAsString uuidData
                            , roles = [ User.UserRole ]
                            , recentLoginEmails = []
                            , verified = Nothing
                            }
                    in
                    ( { model
                        | localUuidData = model.localUuidData |> Maybe.map LocalUUID.step
                      }
                        |> addNewUser email user
                    , Lamdera.sendToFrontend clientId (UserSignedIn (Just user))
                    )


addNewUser email user model =
    { model
        | users = Dict.insert email user model.users
        , userNameToEmailString = Dict.insert user.username email model.userNameToEmailString
    }


getUserWithUsername : BackendModel -> User.Username -> Maybe User.User
getUserWithUsername model username =
    Dict.get username model.userNameToEmailString
        |> Maybe.andThen (\email -> Dict.get email model.users)



-- HELPERS


handleExistingSession : BackendModel -> String -> SessionId -> ClientId -> Int -> ( BackendModel, Cmd BackendMsg )
handleExistingSession model username sessionId clientId magicToken =
    case getUserWithUsername model username of
        Just user ->
            ( { model
                | users = User.setAsVerified model.time user model.users
                , sessionDict = AssocList.insert sessionId user.emailString model.sessionDict |> Debug.log "XX, sessionDict (1)"
              }
            , Cmd.batch
                [ Lamdera.sendToFrontend sessionId
                    (AuthToFrontend <| Auth.Common.AuthSignInWithTokenResponse (Ok <| User.signinDataOfUser user))
                ]
            )

        Nothing ->
            ( model, Lamdera.sendToFrontend clientId (AuthToFrontend <| Auth.Common.AuthSignInWithTokenResponse (Err magicToken)) )


handleNoSession : BackendModel -> Time.Posix -> SessionId -> ClientId -> Int -> ( BackendModel, Cmd BackendMsg )
handleNoSession model time sessionId clientId magicToken =
    case AssocList.get sessionId model.pendingLogins of
        Just pendingLogin ->
            if
                (pendingLogin.loginAttempts < MagicLink.LoginForm.maxLoginAttempts)
                    && (Duration.from pendingLogin.creationTime time |> Quantity.lessThan Duration.hour)
            then
                if magicToken == pendingLogin.loginCode then
                    case
                        Dict.toList model.users
                            |> List.Extra.find (\( _, user ) -> user.email == pendingLogin.emailAddress)
                    of
                        Just ( userId, user ) ->
                            ( { model
                                | sessionDict = AssocList.insert sessionId userId model.sessionDict
                                , pendingLogins = AssocList.remove sessionId model.pendingLogins
                                , users = User.setAsVerified model.time user model.users
                              }
                            , User.signinDataOfUser user
                                |> Ok
                                |> (Auth.Common.AuthSignInWithTokenResponse >> AuthToFrontend)
                                |> Lamdera.sendToFrontend sessionId
                            )

                        Nothing ->
                            ( model
                            , Err magicToken
                                |> (Auth.Common.AuthSignInWithTokenResponse >> AuthToFrontend)
                                |> Lamdera.sendToFrontend clientId
                            )

                else
                    ( { model
                        | pendingLogins =
                            AssocList.insert
                                sessionId
                                { pendingLogin | loginAttempts = pendingLogin.loginAttempts + 1 }
                                model.pendingLogins
                      }
                    , Err magicToken |> (Auth.Common.AuthSignInWithTokenResponse >> AuthToFrontend) |> Lamdera.sendToFrontend clientId
                    )

            else
                ( model, Err magicToken |> (Auth.Common.AuthSignInWithTokenResponse >> AuthToFrontend) |> Lamdera.sendToFrontend clientId )

        Nothing ->
            ( model, Err magicToken |> (Auth.Common.AuthSignInWithTokenResponse >> AuthToFrontend) |> Lamdera.sendToFrontend clientId )


getLoginData : User.Id -> User.User -> Types.BackendModel -> Result Types.BackendDataStatus User.SignInData
getLoginData userId user_ model =
    User.signinDataOfUser user_ |> Ok


getUserFromSessionId : SessionId -> BackendModel -> Maybe ( User.Id, User.User )
getUserFromSessionId sessionId model =
    AssocList.get sessionId model.sessionDict
        |> Maybe.andThen (\userId -> Dict.get userId model.users |> Maybe.map (Tuple.pair userId))



-- HELPERS FOR ADDUSER


addUser1 : BackendModel -> ClientId -> User.EmailString -> EmailAddress -> String -> String -> ( BackendModel, Cmd BackendMsg )
addUser1 model clientId emailString emailAddress realname username =
    if emailNotRegistered emailString model.users then
        case Dict.get username model.users of
            Just _ ->
                ( model, Lamdera.sendToFrontend clientId (RegistrationError "That username is already registered") )

            Nothing ->
                addUser2 model clientId emailString emailAddress realname username

    else
        ( model, Lamdera.sendToFrontend clientId (RegistrationError "That email is already registered") )


addUser2 model clientId emailString emailAddress realname username =
    case model.localUuidData of
        Nothing ->
            ( model, Lamdera.sendToFrontend clientId (GotMessage "Error: no model.localUuidData") )

        Just uuidData ->
            let
                user =
                    { fullname = realname
                    , username = username
                    , email = emailAddress
                    , emailString = emailString
                    , created_at = model.time
                    , updated_at = model.time
                    , id = LocalUUID.extractUUIDAsString uuidData
                    , roles = [ User.UserRole ]
                    , recentLoginEmails = []
                    , verified = Nothing
                    }
            in
            ( { model
                | localUuidData = model.localUuidData |> Maybe.map LocalUUID.step
              }
                |> addNewUser emailString user
            , Lamdera.sendToFrontend clientId (UserRegistered user)
            )



-- STUFF


emailNotRegistered : User.EmailString -> Dict.Dict String User.User -> Bool
emailNotRegistered email users =
    case Dict.get email users of
        Nothing ->
            True

        Just _ ->
            False


getLoginCode : Time.Posix -> { a | secretCounter : Int } -> ( { a | secretCounter : Int }, Result () Int )
getLoginCode time model =
    case getUniqueId time model of
        ( model2, id ) ->
            ( model2, loginCodeFromId id )


loginCodeFromId : Id String -> Result () Int
loginCodeFromId id =
    case Id.toString id |> String.left MagicLink.LoginForm.loginCodeLength |> Hex.fromString of
        Ok int ->
            case String.fromInt int |> String.left MagicLink.LoginForm.loginCodeLength |> String.toInt of
                Just int2 ->
                    Ok int2

                Nothing ->
                    Err ()

        Err _ ->
            Err ()


getUniqueId : Time.Posix -> { a | secretCounter : Int } -> ( { a | secretCounter : Int }, Id String )
getUniqueId time model =
    ( { model | secretCounter = model.secretCounter + 1 }
    , Config.secretKey
        ++ ":"
        ++ String.fromInt model.secretCounter
        ++ ":"
        ++ String.fromInt (Time.posixToMillis time)
        |> Sha256.sha256
        |> Id.fromString
    )


sendLoginEmail_ :
    (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg)
    -> EmailAddress
    -> Int
    -> Cmd backendMsg
sendLoginEmail_ msg emailAddress loginCode =
    let
        _ =
            Debug.log "XX: ML.BE, sendLoginEmail_" loginCode

        _ =
            Debug.log "XX: emailAddress" emailAddress

        _ =
            Debug.log "XX: loginCode" loginCode
    in
    { from = { name = "", email = noReplyEmailAddress }
    , to = List.Nonempty.fromElement { name = "", email = emailAddress }
    , subject = loginEmailSubject
    , body =
        Postmark.BodyBoth
            (loginEmailContent loginCode)
            ("Here is your code " ++ String.fromInt loginCode ++ "\n\nPlease type it in the XXX login page you were previously on.\n\nIf you weren't expecting this email you can safely ignore it.")
    , messageStream = "outbound"
    }
        |> Postmark.sendEmail msg Config.postmarkApiKey


loginEmailContent : Int -> Email.Html.Html
loginEmailContent loginCode =
    Email.Html.div
        [ Email.Html.Attributes.padding "8px" ]
        [ Email.Html.div [] [ Email.Html.text "Here is your code." ]
        , Email.Html.div
            [ Email.Html.Attributes.fontSize "36px"
            , Email.Html.Attributes.fontFamily "monospace"
            ]
            (String.fromInt loginCode
                |> String.toList
                |> List.map
                    (\char ->
                        Email.Html.span
                            [ Email.Html.Attributes.padding "0px 3px 0px 4px" ]
                            [ Email.Html.text (String.fromChar char) ]
                    )
                |> (\a ->
                        List.take (MagicLink.LoginForm.loginCodeLength // 2) a
                            ++ [ Email.Html.span
                                    [ Email.Html.Attributes.backgroundColor "black"
                                    , Email.Html.Attributes.padding "0px 4px 0px 5px"
                                    , Email.Html.Attributes.style "vertical-align" "middle"
                                    , Email.Html.Attributes.fontSize "2px"
                                    ]
                                    []
                               ]
                            ++ List.drop (MagicLink.LoginForm.loginCodeLength // 2) a
                   )
            )
        , Email.Html.text "Please type it in the login page you were previously on."
        , Email.Html.br [] []
        , Email.Html.br [] []
        , Email.Html.text "If you weren't expecting this email you can safely ignore it."
        ]


loginEmailSubject : NonemptyString
loginEmailSubject =
    String.Nonempty.NonemptyString 'L' "ogin code"


noReplyEmailAddress : EmailAddress
noReplyEmailAddress =
    EmailAddress.EmailAddress
        { localPart = "hello"
        , tags = []
        , domain = "elm-kitchen-sink.lamdera"
        , tld = [ "app" ]
        }
