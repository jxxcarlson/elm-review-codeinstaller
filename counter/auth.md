```

```

# Summary of Auth Messages

## Phase I

1. `AuthFrontendMsg SubmitEmailForSignIn`
2. `AuthFrontendMsg (AuthSigninRequested { email = Just "jxxcarlson@gmail.com", methodId = "EmailMagicLink" })`

3.  `AuthToBackend (AuthSigninInitiated { baseUrl = { fragment = Nothing, host = "localhost", path = "/admin", port_ = Just 8000, protocol = Http, query = Nothing }, methodId = "EmailMagicLink", username = Just "jxxcarlson@gmail.com" })`
4.   `AuthToFrontend (ReceivedMessage (Ok "We have sent you a login email at jxxcarlson@gmail.com"))`

## Phase II

1. `AuthFrontendMsg (ReceivedSigninCode "14477875")`
2. `AuthToBackend (AuthSigInWithToken 14477875)`
3. `AuthToFrontend (AuthSignInWithTokenResponse (Ok { email = "jxxcarlson@gmail.com", name = "Jim Carlson", roles = [AdminRole,UserRole], username = "jxxcarlson" }))`
4. `SignInUser { email = "jxxcarlson@gmail.com", name = "Jim Carlson", roles = [AdminRole,UserRole], username = "jxxcarlson" }`


## Types

```
type FrontendMsg
    = ...
    | AuthFrontendMsg MagicLink.Types.Msg
    
type BackendMsg
    = ...
    | AuthBackendMsg Auth.Common.BackendMsg
    
type ToFrontend
    = ...
    | AuthToFrontend Auth.Common.ToFrontend
    
type ToBackend
    = ...
    | AuthToBackend Auth.Common.ToBackend
```

## Messages

```
-- FRONTEND
updateLoaded : FrontendMsg -> LoadedModel -> ( LoadedModel, Cmd FrontendMsg )
  ...
  AuthFrontendMsg authToFrontendMsg ->
    MagicLink.Auth.update authToFrontendMsg model.magicLinkModel 
    |> Tuple.mapFirst (\magicLinkModel -> { model | magicLinkModel = magicLinkModel })
    
updateFromBackendLoaded : ToFrontend -> LoadedModel -> ( LoadedModel, Cmd FrontendMsg )
  ...       
  AuthToFrontend authToFrontendMsg ->
    MagicLink.Auth.updateFromBackend authToFrontendMsg model.magicLinkModel 
    |> Tuple.mapFirst 
      (\magicLinkModel -> { model | magicLinkModel = magicLinkModel })
    

            
-- BACKEND
update : BackendMsg -> BackendModel -> ( BackendModel, Cmd BackendMsg )
  AuthBackendMsg authMsg ->
    Auth.Flow.backendUpdate (MagicLink.Auth.backendConfig model) 

updateFromBackendLoaded : ToFrontend -> LoadedModel -> ( LoadedModel, Cmd FrontendMsg )
  AutoLogin sessionId loginData ->
    ( model, Lamdera.sendToFrontend sessionId (AuthToFrontend <| Auth.Common.AuthSignInWithTokenResponse <| Ok <| loginData) )

            
```

# Log


1. `F : AuthFrontendMsg SubmitEmailForSignIn`

2. `F   : AuthFrontendMsg (AuthSigninRequested { email = Just "jxxcarlson@gmail.com", methodId = "EmailMagicLink" })`
 
3. `F▶️  : AuthToBackend (AuthSigninInitiated { baseUrl = { fragment = Nothing, host = "localhost", path = "/admin", port_ = Just 8000, protocol = Http, query = Nothing }, methodId = "EmailMagicLink", username = Just "jxxcarlson@gmail.com" })`

4. `▶️B: AuthToBackend (AuthSigninInitiated { baseUrl = { fragment = Nothing, host = "localhost", path = "/admin", port_ = Just 8000, protocol = Http, query = Nothing }, methodId = "EmailMagicLink", username = Just "jxxcarlson@gmail.com" })`

5. `◀️B: AuthToFrontend (ReceivedMessage (Ok "We have sent you a login email at jxxcarlson@gmail.com"))`

6. `F◀️: AuthToFrontend (ReceivedMessage (Ok "We have sent you a login email at jxxcarlson@gmail.com"))`

7. `F: AuthFrontendMsg (ReceivedSigninCode "14477875")`


8. `F▶️: AuthToBackend (AuthSigInWithToken 14477875)`


9. `▶️B: AuthToBackend (AuthSigInWithToken 14477875)`


10. `◀️B : AuthToFrontend (AuthSignInWithTokenResponse (Ok { email = "jxxcarlson@gmail.com", name = "Jim Carlson", roles = [AdminRole,UserRole], username = "jxxcarlson" }))`


11. `F◀️  : AuthToFrontend (AuthSignInWithTokenResponse (Ok { email = "jxxcarlson@gmail.com", name = "Jim Carlson", roles = [AdminRole,UserRole], username = "jxxcarlson" }))`

12. `F: SignInUser { email = "jxxcarlson@gmail.com", name = "Jim Carlson", roles = [AdminRole,UserRole], username = "jxxcarlson" }`