module Pages.SignIn exposing (headerView, init, showCurrentUser, view)

import Auth.Common
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import MagicLink.LoginForm
import MagicLink.Types
import Route
import Url
import User
import View.Button
import View.Color
import View.Common
import View.Input


type alias Model =
    MagicLink.Types.Model


init : Url.Url -> Model
init url =
    { count = 0
    , signInStatus = MagicLink.Types.NotSignedIn
    , currentUserData = Nothing
    , currentUser = Nothing
    , signInForm = MagicLink.LoginForm.init
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
                , Element.el [ Element.paddingXY 13 0, Element.Font.color (Element.rgb 0 0 1) ] (Element.text <| username ++ ", you are now registered as " ++ email)
                ]

        MagicLink.Types.ErrorNotRegistered message ->
            Element.column []
                [ signUp model
                , Element.el [ Element.Font.color (Element.rgb 1 0 0) ] (Element.text message)
                ]


signedInView : Model -> Element MagicLink.Types.Msg
signedInView model =
    case model.currentUserData of
        Nothing ->
            Element.none

        Just userData ->
            -- TODO SIGNOUT BUTTON
            signOutButton userData.username


signInView : Model -> Element MagicLink.Types.Msg
signInView model =
    Element.column []
        [ Element.el [ Element.Font.semiBold, Element.Font.size 24 ] (Element.text "Sign in")
        , MagicLink.LoginForm.view model.signInForm
        , Element.row
            [ Element.spacing 12
            , Element.paddingEach { left = 18, right = 0, top = 0, bottom = 0 }
            ]
            [ Element.el [] (Element.text "Need to sign up?  "), View.Button.openSignUp ]
        , Element.el [ Element.paddingXY 12 24, Element.Font.bold, Element.Font.color (Element.rgb 80 0 0) ] (Element.text model.message)
        ]


signInAfterRegisteringView : Model -> Element MagicLink.Types.Msg
signInAfterRegisteringView model =
    Element.column []
        [ Element.el [ Element.Font.semiBold, Element.Font.size 24 ] (Element.text "Sign in")
        , MagicLink.LoginForm.view model.signInForm
        ]


signUp : Model -> Element MagicLink.Types.Msg
signUp model =
    Element.column [ Element.spacing 18, topPadding ]
        [ Element.el [ Element.Font.semiBold, Element.Font.size 24 ] (Element.text "Sign up")
        , View.Input.template "Real Name" model.realname MagicLink.Types.InputRealname
        , View.Input.template "User Name" model.username MagicLink.Types.InputUsername
        , View.Input.template "Email" model.email MagicLink.Types.InputEmail
        , Element.row [ Element.spacing 18 ]
            [ signUpButton
            , View.Button.closeSignUp
            ]
        , Element.el [ Element.Font.size 14, Element.Font.italic, Element.Font.color View.Color.darkGray ] (Element.text model.message)
        ]


headerView : Model -> Route.Route -> { window : { width : Int, height : Int }, isCompact : Bool } -> Element MagicLink.Types.Msg
headerView model route config =
    Element.el
        [ Element.Background.color View.Color.blue
        , Element.paddingXY 24 16
        , Element.width (Element.px 420) --(Element.px config.window.width)
        , Element.alignTop
        ]
        (Element.wrappedRow
            [ Element.spacing 24
            , Element.Background.color View.Color.blue
            , Element.Font.color (Element.rgb 1 1 1)
            ]
            [ if User.isAdmin model.currentUserData then
                Element.link
                    (View.Common.linkStyle route Route.AdminRoute)
                    { url = Route.encode Route.AdminRoute, label = Element.text "Admin" }

              else
                Element.none
            , case model.currentUserData of
                Just currentUserData_ ->
                    signOutButton currentUserData_.username

                Nothing ->
                    Element.link
                        (View.Common.linkStyle route Route.SignInRoute)
                        { url = Route.encode Route.SignInRoute
                        , label =
                            Element.el []
                                (case model.currentUserData of
                                    Just currentUserData_ ->
                                        signOutButton currentUserData_.username

                                    Nothing ->
                                        Element.text "Sign in"
                                )
                        }
            ]
        )



-- BUTTON


signUpButton : Element.Element MagicLink.Types.Msg
signUpButton =
    button MagicLink.Types.SubmitSignUp "Submit"


showCurrentUser : { a | magicLinkModel : { b | currentUserData : Maybe { c | username : String } } } -> Element MagicLink.Types.Msg
showCurrentUser model =
    case model.magicLinkModel.currentUserData of
        Nothing ->
            Element.none

        Just userData ->
            signOutButton userData.username


signOutButton : String -> Element.Element MagicLink.Types.Msg
signOutButton str =
    Element.el [ Element.paddingXY 24 0 ] (button MagicLink.Types.SignOut ("Sign out " ++ str))


cancelSignUpButton =
    button MagicLink.Types.CancelSignUp "Cancel"


button msg label =
    Element.Input.button
        buttonStyle
        { onPress = Just msg
        , label =
            Element.el buttonLabelStyle (Element.text label)
        }


highlightableButton condition msg label =
    Element.Input.button
        buttonStyle
        { onPress = Just msg
        , label =
            Element.el (buttonLabelStyle ++ highlight condition) (Element.text label)
        }


buttonStyle =
    [ Element.Font.color (Element.rgb 0.2 0.2 0.2)
    , Element.height Element.shrink
    , Element.paddingXY 8 8
    , Element.Border.rounded 8
    , Element.Background.color View.Color.blue
    , Element.Font.color View.Color.white
    , Element.mouseDown
        [ Element.Background.color View.Color.buttonHighlight
        ]
    ]


buttonLabelStyle =
    [ Element.centerX
    , Element.centerY
    , Element.Font.size 15
    ]


highlight condition =
    if condition then
        [ Element.Font.color View.Color.yellow ]

    else
        [ Element.Font.color View.Color.white ]


topPadding =
    Element.paddingEach { left = 0, right = 0, top = 48, bottom = 0 }
