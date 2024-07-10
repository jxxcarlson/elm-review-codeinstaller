module View.Common exposing (linkStyle)

import Element
import Element.Font
import Route
import View.Color


linkStyle : Route.Route -> Route.Route -> List (Element.Attribute msg)
linkStyle currentRoute route =
    if currentRoute == route then
        [ Element.Font.underline, Element.Font.color View.Color.yellow ]

    else
        [ Element.Font.color View.Color.white ]
