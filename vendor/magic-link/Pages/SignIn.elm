module Pages.SignIn exposing (init, view)

import Auth.Common
import Element exposing (Element)
import Element.Font
import MagicLink.Types
import Url


type alias Model =
    MagicLink.Types.Model


init : Url.Url -> Model
init url =
    { count = 0
    , signInStatus = MagicLink.Types.NotSignedIn
    , currentUserData = Nothing
    , currentUser = Nothing

    -- , signInForm = MagicLink.LoginForm.init
    , signInState = MagicLink.Types.SisSignedOut
    , loginErrorMessage = Nothing
    , realname = ""
    , username = ""
    , email = ""
    , message = ""
    , authFlow = Auth.Common.Idle
    , authRedirectBaseUrl = url
    }


update : MagicLink.Types.Msg -> Model -> Model
update msg model =
    case msg of
        MagicLink.Types.InputRealname str ->
            { model | realname = str }

        _ ->
            model


view : (MagicLink.Types.Msg -> msg) -> Model -> Element MagicLink.Types.Msg
view toSelf model =
    case model.signInStatus of
        MagicLink.Types.NotSignedIn ->
            signInView model

        MagicLink.Types.SignedIn ->
            signedInView model

        MagicLink.Types.SigningUp ->
            signUp model

        MagicLink.Types.SuccessfulRegistration username email ->
            Element.column []
                [ signInAfterRegisteringView model
                , Element.el [ Element.Font.color (Element.rgb 0 0 1) ] (Element.text <| username ++ ", you are now registered as " ++ email)
                ]

        MagicLink.Types.ErrorNotRegistered message ->
            Element.column []
                [ signUp model
                , Element.el [ Element.Font.color (Element.rgb 1 0 0) ] (Element.text message)
                ]


signedInView : Model -> Element MagicLink.Types.Msg
signedInView model =
    Element.text "signedInView: implement"


signInView : Model -> Element MagicLink.Types.Msg
signInView model =
    Element.text "signInView: implement"


signInAfterRegisteringView : Model -> Element MagicLink.Types.Msg
signInAfterRegisteringView model =
    Element.text "signInAfterRegisteringView: implement"


signUp : Model -> Element MagicLink.Types.Msg
signUp model =
    Element.text "signUp: implement"
