module View.MyElement exposing
    ( Label
    , emailAddressLink
    , errorColor
    , label
    , onEnter
    , primaryButton
    , routeLinkNewTab
    , secondaryButton
    )

import Element exposing (Element)
import Element.Background
import Element.Font
import Element.Input
import Html
import Html.Attributes
import Html.Events
import Json.Decode as Decode
import Martin
import Route exposing (Route)
import View.Common


errorColor =
    Element.rgb 1 0 0


type alias Label msg =
    { element : Element msg, id : Martin.HtmlId }


onEnter : msg -> Element.Attribute msg
onEnter message =
    Html.Events.on "enter" (Decode.succeed message) |> Element.htmlAttribute


label : String -> List (Element.Attribute msg) -> Element msg -> { element : Element msg, id : Element.Input.Label msg }



-- TODO: this is likely not quite right, I am setting the label to an empty string FOR NOW


label idString attrList element =
    { element = element
    , id = Element.Input.labelAbove (Martin.elementId_ idString :: attrList) (Element.text "")
    }


routeLinkNewTab : Route -> Route -> Element msg
routeLinkNewTab currentRoute route =
    Element.link
        (View.Common.linkStyle currentRoute route)
        { url = Route.encode route, label = Element.text (Route.encode route) }


secondaryButton : List (Element.Attribute msg) -> msg -> String -> Element msg
secondaryButton attrList message txt =
    Element.Input.button attrList { onPress = Just message, label = Element.el secondaryButtonsStyle (Element.text txt) }


primaryButton : Martin.HtmlId -> msg -> String -> Element msg
primaryButton htmlId message txt =
    Element.Input.button [ Martin.elementId htmlId ] { onPress = Just message, label = Element.el primaryButtonsStyle (Element.text txt) }


primaryButtonsStyle =
    [ Element.Background.color (Element.rgb 0.5 0.2 0.2)
    , Element.Font.color (Element.rgb 1 1 1)
    , Element.Font.size 14
    , Element.padding 8
    , Element.mouseDown [ Element.Background.color (Element.rgb 1 0.1 0.1) ]
    ]


secondaryButtonsStyle =
    [ Element.Background.color (Element.rgb 0.2 0.2 0.5)
    , Element.Font.color (Element.rgb 1 1 1)
    , Element.Font.size 14
    , Element.padding 8
    , Element.mouseDown [ Element.Background.color (Element.rgb 0.4 0.4 1) ]
    ]


emailAddressLink : String -> Element msg
emailAddressLink email =
    Html.a [ Html.Attributes.href ("mailto:" ++ email) ] [ Html.text email ] |> Element.html
