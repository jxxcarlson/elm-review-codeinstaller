module MagicLink.LoginForm exposing
    ( init
    , loginCodeLength
    , maxLoginAttempts
    , validateLoginCode
    , view
    )

import Config
import Dict
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import EmailAddress exposing (EmailAddress)
import Html.Attributes
import MagicLink.Types exposing (EnterEmail_, EnterLoginCode_, LoginCodeStatus(..), SigninForm(..))
import Martin
import Route
import Types exposing (FrontendMsg)
import View.MyElement as MyElement


validateLoginCode : String -> Result String Int
validateLoginCode text =
    if String.any (\char -> Char.isDigit char |> not) text then
        Err "Must only contain digits 0-9"

    else if String.length text == loginCodeLength then
        case String.toInt text of
            Just int ->
                Ok int

            Nothing ->
                Err "Invalid code"

    else
        Err ""


loginCodeLength : number
loginCodeLength =
    8


emailInput : msg -> (String -> msg) -> String -> String -> Maybe String -> Element msg
emailInput onSubmit onChange text labelText maybeError =
    let
        label =
            MyElement.label
                (Martin.idToString emailInputId)
                [ Element.Font.bold ]
                (Element.text labelText)
    in
    Element.column
        [ Element.spacing 4 ]
        [ Element.column
            []
            [ label.element
            , Element.Input.email
                [ -- Element.Events.onKey Element.Events.enter onSubmit
                  -- TODO: it is doubtful that the below is correct
                  MyElement.onEnter onSubmit
                , case maybeError of
                    Just _ ->
                        Element.Border.color MyElement.errorColor

                    Nothing ->
                        Martin.noAttr
                ]
                { text = text
                , onChange = onChange
                , placeholder = Just <| Element.Input.placeholder [] <| Element.text "abc@def.com"
                , label = label.id
                }
            ]
        , Maybe.map errorView maybeError |> Maybe.withDefault Element.none
        ]


errorView : String -> Element msg
errorView errorMessage =
    Element.paragraph
        [ Element.width Element.shrink
        , Element.Font.color MyElement.errorColor
        , Element.Font.medium
        ]
        [ Element.text errorMessage ]


view : Types.LoadedModel -> SigninForm -> Element FrontendMsg
view model loginForm =
    Element.column
        [ Element.padding 16
        , Element.centerX
        , Element.centerY

        -- TODO:, Element.widthMax 520
        , Element.spacing 24
        ]
        [ case loginForm of
            EnterEmail enterEmail2 ->
                enterEmailView enterEmail2

            EnterSigninCode enterLoginCode ->
                enterLoginCodeView enterLoginCode
        , Element.paragraph
            [ Element.Font.center ]
            [ Element.text "If you're having trouble logging in, we can be reached at "
            , MyElement.emailAddressLink Config.contactEmail
            ]
        ]


enterLoginCodeView : EnterLoginCode_ -> Element FrontendMsg
enterLoginCodeView model =
    let
        -- label : MyElement.Label
        label =
            MyElement.label
                (Martin.idToString loginCodeInputId)
                []
                (Element.column
                    [ Element.Font.center ]
                    [ Element.paragraph
                        [ Element.Font.size 30, Element.Font.bold ]
                        [ Element.text "Check your email for a code" ]
                    , Element.paragraph
                        [ Element.width Element.shrink ]
                        [ Element.text "An email has been sent to "
                        , Element.el
                            [ Element.Font.bold ]
                            (Element.text (EmailAddress.toString model.sentTo))
                        , Element.text " containing a code. Please enter that code here."
                        ]
                    ]
                )
    in
    Element.column
        [ Element.spacing 24 ]
        [ label.element
        , Element.column
            [ Element.spacing 6, Element.centerX, Element.width Element.shrink, Element.moveRight 18 ]
            [ Element.Input.text
                [ -- Element.Font.letterSpacing 26
                  Element.paddingEach { left = 6, right = 0, top = 2, bottom = 8 }
                , Element.Font.family [ Element.Font.monospace ]
                , Element.Font.size 14
                , Html.Attributes.attribute "inputmode" "numeric" |> Element.htmlAttribute
                , Html.Attributes.type_ "number" |> Element.htmlAttribute
                , Element.Border.width 1
                , Element.Background.color (Element.rgba 0 0 0.2 0)
                ]
                { onChange = Types.AuthFrontendMsg << MagicLink.Types.ReceivedSigninCode
                , text = model.loginCode
                , placeholder = Nothing --Just (Element.Input.placeholder [] (Element.text "12345678"))
                , label = label.id
                }
            , if Dict.size model.attempts < maxLoginAttempts then
                case validateLoginCode model.loginCode of
                    Ok loginCode ->
                        case Dict.get loginCode model.attempts of
                            Just NotValid ->
                                errorView "Incorrect code"

                            _ ->
                                Element.paragraph
                                    []
                                    [ Element.text "Submitting..." ]

                    Err error ->
                        errorView error

              else
                Element.text "Too many incorrect attempts. Please refresh the page and try again."
            ]
        ]


emailInputId : Martin.HtmlId
emailInputId =
    Martin.HtmlId "loginForm_emailInput"


submitEmailButtonId : Martin.HtmlId
submitEmailButtonId =
    Martin.HtmlId "loginForm_loginButton"


cancelButtonId : Martin.HtmlId
cancelButtonId =
    Martin.HtmlId "loginForm_cancelButton"


loginCodeInputId : Martin.HtmlId
loginCodeInputId =
    Martin.HtmlId "loginForm_loginCodeInput"


maxLoginAttempts : number
maxLoginAttempts =
    10


enterEmailView : EnterEmail_ -> Element FrontendMsg
enterEmailView model =
    Element.column
        [ Element.spacing 16 ]
        [ emailInput
            (Types.AuthFrontendMsg MagicLink.Types.SubmitEmailForSignIn)
            (Types.AuthFrontendMsg << MagicLink.Types.TypedEmailInSignInForm)
            model.email
            "Enter your email address"
            (case ( model.pressedSubmitEmail, validateEmail model.email ) of
                ( True, Err error ) ->
                    Just error

                _ ->
                    Nothing
            )
        , Element.paragraph
            []
            [ Element.text "By continuing, you agree to our Terms of Service."

            -- TODO: below, Route,HomepageRoute is a placeholder
            , MyElement.routeLinkNewTab Route.HomepageRoute Route.TermsOfServiceRoute
            , Element.text "."
            ]
        , Element.row
            [ Element.spacing 16 ]
            [ MyElement.secondaryButton [ Martin.elementId cancelButtonId ] (Types.AuthFrontendMsg MagicLink.Types.CancelSignIn) "Cancel"
            , MyElement.primaryButton submitEmailButtonId (Types.AuthFrontendMsg MagicLink.Types.SubmitEmailForSignIn) "Sign in"
            ]
        , if model.rateLimited then
            errorView "Too many sign in attempts have been made. Please try again later."

          else
            Element.none
        ]


validateEmail : String -> Result String EmailAddress
validateEmail text =
    EmailAddress.fromString text
        |> Result.fromMaybe
            (if String.isEmpty text then
                "Enter your email first"

             else
                "Invalid email address"
            )


init : SigninForm
init =
    EnterEmail
        { email = ""
        , pressedSubmitEmail = False
        , rateLimited = False
        }
