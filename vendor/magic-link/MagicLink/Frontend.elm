module MagicLink.Frontend exposing
    ( enterEmail
    , handleRegistrationError
    , handleSignInError
    , signIn
    , signInWithCode
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
    -- TODO: implement
    ( model, Cmd.none )


enterEmail : Model -> String -> ( Model, Cmd msg )
enterEmail model email =
    -- TODO: implement
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


signInWithCode : Model -> String -> ( Model, Cmd msg )
signInWithCode model signInCode =
    -- TODO: Implement
    -- The signInCode is the string the user received via Postmark via email
    -- This string must be converted to an integer and then sent to the backend
    -- as loginCode to complete the sign in process
    -- Lamdera.sendToBackend ((AuthToBackend << Auth.Common.AuthSigInWithToken) loginCode)
    ( model, Cmd.none )



-- HELPERS
