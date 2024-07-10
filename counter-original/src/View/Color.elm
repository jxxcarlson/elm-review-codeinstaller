module View.Color exposing
    ( blue
    , buttonHighlight
    , darkGray
    , white
    , yellow
    )

import Element as E


blue : E.Color
blue =
    -- used
    E.rgb255 64 64 109


yellow : E.Color
yellow =
    E.rgb 1.0 0.9 0.7


white : E.Color
white =
    E.rgb 255 255 255


darkGray : E.Color
darkGray =
    gray 0.2


buttonHighlight : E.Color
buttonHighlight =
    E.rgb255 100 80 255


gray : Float -> E.Color
gray g =
    E.rgb g g g
