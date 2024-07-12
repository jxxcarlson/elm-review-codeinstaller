module MagicLink.Frontend exposing
    ( enterEmail
    , handleRegistrationError
    , handleSignInError
    , signIn
    , submitEmailForSignin
    , updateMagicLinkModelInModel
    )

import Auth.Common
import Dict
import EmailAddress
import Lamdera
import MagicLink.Helper as Helper
import MagicLink.Types exposing (SigninFormState(..))
import Route exposing (Route(..))
import Types
    exposing
        ( FrontendMsg(..)
        , LoadedModel
        , ToBackend(..)
        )
import User


type alias Model =
    MagicLink.Types.Model


updateMagicLinkModelInModel model =
    \magicLinkModel -> { model | magicLinkModel = magicLinkModel }


submitEmailForSignin : Model -> ( Model, Cmd FrontendMsg )
submitEmailForSignin model =
    case model.signInForm of
        EnterEmail signInForm_ ->
            case EmailAddress.fromString signInForm_.email of
                Just email ->
                    let
                        model2 =
                            { model | signInForm = EnterSigninCode { sentTo = email, loginCode = "", attempts = Dict.empty } }
                    in
                    ( model2, Helper.trigger <| AuthFrontendMsg <| MagicLink.Types.AuthSigninRequested { methodId = "EmailMagicLink", email = Just signInForm_.email } )

                Nothing ->
                    ( { model | signInForm = EnterEmail { signInForm_ | pressedSubmitEmail = True } }, Cmd.none )

        EnterSigninCode _ ->
            ( model, Cmd.none )


enterEmail : Model -> String -> ( Model, Cmd msg )
enterEmail model email =
    case model.signInForm of
        EnterEmail signinForm_ ->
            let
                signinForm =
                    { signinForm_ | email = email }
            in
            ( { model | signInForm = EnterEmail signinForm }, Cmd.none )

        EnterSigninCode loginCode_ ->
            -- TODO: complete this
            --  EnterLoginCode{ sentTo : EmailAddress, loginCode : String, attempts : Dict Int LoginCodeStatus }
            ( model, Cmd.none )


handleRegistrationError : Model -> String -> ( Model, Cmd msg )
handleRegistrationError model str =
    ( { model | signInStatus = MagicLink.Types.ErrorNotRegistered str }, Cmd.none )


handleSignInError : Model -> String -> ( Model, Cmd msg )
handleSignInError model message =
    ( { model | loginErrorMessage = Just message, signInStatus = MagicLink.Types.ErrorNotRegistered message }, Cmd.none )


signIn model userData =
    let
        oldMagicLinkModel =
            model.magicLinkModel
    in
    ( { model
        | magicLinkModel = { oldMagicLinkModel | currentUserData = Just userData, signInStatus = MagicLink.Types.SignedIn }
      }
    , Cmd.none
    )



-- HELPERS
