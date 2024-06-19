module Pages.Counter exposing (..)

import Element exposing (Element)
import Html exposing (Html, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Types exposing (FrontendMsg(..), LoadedModel)


view model =
    Html.div [ style "padding" "50px" ]
        [ Html.button [ onClick Increment ] [ text "+" ]
        , Html.div [ style "padding" "10px" ] [ Html.text (String.fromInt model.counter) ]
        , Html.button [ onClick Decrement ] [ text "-" ]
        , Html.div [ style "padding-top" "15px", style "padding-bottom" "15px" ] [ Html.text "Click me then refresh me!" ]
        , Html.button [ onClick Reset ] [ text "Reset" ]
        ]
