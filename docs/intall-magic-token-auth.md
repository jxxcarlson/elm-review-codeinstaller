# Implementing the Magic Token system in another app

The following additions must be made:

## Types

### FrontendMsg

```
| SubmitEmailForToken
| CancelSignIn
| TypedEmailInSignInForm String
| UseReceivedCodetoSignIn String
| SignOut
```    

### BackendMsg

```
| AutoLogin SessionId User.LoginData
| BackendGotTime SessionId ClientId ToBackend Time.Posix
| SentLoginEmail Time.Posix EmailAddress (Result Http.Error Postmark.PostmarkSendResponse)
| AuthenticationConfirmationEmailSent (Result Http.Error Postmark.PostmarkSendResponse)
```

### ToBackend

```
| CheckLoginRequest
| SigInWithTokenRequest Int
| GetSignInTokenRequest EmailAddress
| SignOutRequest (Maybe User.LoginData)
```

### ToFrontend

```
| CheckSignInResponse (Result BackendDataStatus User.LoginData)
| SignInWithTokenResponse (Result Int User.LoginData)
| GetLoginTokenRateLimited
| LoggedOutSession
| RegistrationError String
| SignInError String
```


### LoadedModel

```
, loginForm : Token.Types.LoginForm
, loginErrorMessage : Maybe String
, signInStatus : Token.Types.SignInStatus
, currentUserData : Maybe User.LoginData
```

### BackendModel

```
, secretCounter : Int
, sessionDict : AssocList.Dict SessionId String -- Dict sessionId usernames
, pendingLogins :
    AssocList.Dict
        SessionId
        { loginAttempts : Int
        , emailAddress : EmailAddress
        , creationTime : Time.Posix
        , loginCode : Int
        }
, log : Token.Types.Log
, userDictionary : Dict.Dict String User.User
, sessions : Session.Sessions
, sessionInfo : Session.SessionInfo
```

## Modules to add

```
Token.Types
Token.Backend
Token.Frontend
Token.LoginForm
Pages.SignIn -- attach this to your routing/page system
```

## Add to Backend

### Imports

```
import Token.Backend
```

### Function init

```
, secretCounter = 0
, sessionDict = AssocList.empty
, pendingLogins = AssocList.empty
, log = []
```
### Function update

```
SentLoginEmail _ _ _ ->
            -- TODO
            ( model, Cmd.none )

        AuthenticationConfirmationEmailSent _ ->
            -- TODO
            ( model, Cmd.none )

        AutoLogin sessionId loginData ->
            ( model, Lamdera.sendToFrontend sessionId (SignInWithTokenResponse <| Ok <| loginData) )

        OnConnected sessionId clientId ->
            let
                _ =
                    Debug.log "@##!OnConnected (1)" ( sessionId, clientId )

                maybeUsername : Maybe String
                maybeUsername =
                    BiDict.get sessionId model.sessions

                maybeUserData : Maybe User.LoginData
                maybeUserData =
                    Maybe.andThen (\username -> Dict.get username model.userDictionary) maybeUsername
                        |> Maybe.map User.loginDataOfUser
                        |> Debug.log "@##! OnConnected, loginDataOfUser (2)"
            in
            ( model
            , Cmd.batch
                [ BackendHelper.getAtmosphericRandomNumbers
                , Backend.Session.reconnect model sessionId clientId
                , Lamdera.sendToFrontend clientId (GotKeyValueStore model.keyValueStore)

                ---, Lamdera.sendToFrontend sessionId (GotMessage "Connected")
                , Lamdera.sendToFrontend
                    clientId
                    (InitData
                        { prices = model.prices
                        , productInfo = model.products
                        }
                    )
                , case AssocList.get sessionId model.sessionDict of
                    Just username ->
                        case Dict.get username model.userDictionary of
                            Just user ->
                                -- Lamdera.sendToFrontend sessionId (LoginWithTokenResponse <| Ok <| Debug.log "@##! send loginDATA" <| User.loginDataOfUser user)
                                Process.sleep 60 |> Task.perform (always (AutoLogin sessionId (User.loginDataOfUser user)))

                            Nothing ->
                                Lamdera.sendToFrontend clientId (SignInWithTokenResponse (Err 0))

                    Nothing ->
                        Lamdera.sendToFrontend clientId (SignInWithTokenResponse (Err 1))
                ]
            )
```

### Function updateFromFrontend

```
 AddUser realname username email ->
        Token.Backend.addUser model clientId email realname username

CheckLoginRequest ->
    Token.Backend.checkLogin model clientId sessionId

GetSignInTokenRequest email ->
    Token.Backend.sendLoginEmail model clientId sessionId email

RequestSignup realname username email ->
    Token.Backend.requestSignUp model clientId realname username email

SigInWithTokenRequest loginCode ->
    Token.Backend.loginWithToken model.time sessionId clientId loginCode model

SignOutRequest userData ->
    Token.Backend.signOut model clientId userData
```



## Add to Frontend

### Imports

```
import Token.Frontend
import Token.LoginForm
import Token.Types exposing (LoginForm(..))
```

### Function tryLoading

```
-- in (Loaded { ... }
    , loginForm = Token.LoginForm.init
    , loginErrorMessage = Nothing
    , signInStatus = Token.Types.NotSignedIn
```

```
-- in updateLoaded, case msg
 CancelSignIn ->
            ( { model | route = HomepageRoute }, Cmd.none )

        CancelSignUp ->
            ( { model | signInStatus = Token.Types.NotSignedIn }, Cmd.none )

        OpenSignUp ->
            ( { model | signInStatus = Token.Types.SigningUp }, Cmd.none )

        SubmitEmailForToken ->
            Token.Frontend.submitEmailForToken model

        TypedEmailInSignInForm email ->
            Token.Frontend.enterEmail model (Debug.log "@##" email)

        UseReceivedCodetoSignIn loginCode ->
            Token.Frontend.signInWithCode model loginCode

        SubmitSignUp ->
            Token.Frontend.submitSignUp model

        SignOut ->
            Token.Frontend.signOut model

        InputRealname str ->
            ( { model | realname = str }, Cmd.none )

        InputUsername str ->
            ( { model | username = str }, Cmd.none )

        InputEmail str ->
            ( { model | email = str }, Cmd.none )
```

### Function updateFromBackendLoaded

```
SignInError message ->
    Token.Frontend.handleSignInError model message

RegistrationError str ->
    Token.Frontend.handleRegistrationError model str

CheckSignInResponse _ ->
    ( model, Cmd.none )

SignInWithTokenResponse result ->
    Token.Frontend.signInWithTokenResponse model result

GetLoginTokenRateLimited ->
    ( model, Cmd.none )

LoggedOutSession ->
    ( model, Cmd.none )

UserRegistered user ->
    Token.Frontend.userRegistered model user

UserSignedIn maybeUser ->
    ( { model | signInStatus = Token.Types.NotSignedIn }, Cmd.none )
```


    