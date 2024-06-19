module Pages.Parts exposing
    ( generic
    , linkStyle
    )

import Element exposing (Element)
import Element.Background
import Element.Font
import Route exposing (Route(..))
import Types
import View.Color


generic : Types.LoadedModel -> (Types.LoadedModel -> Element Types.FrontendMsg) -> Element Types.FrontendMsg
generic model view =
    Element.column
        [ Element.width Element.fill, Element.height Element.fill ]
        [ header model model.route { window = model.window, isCompact = True }
        , Element.column
            (Element.padding 20
                :: Element.scrollbarY
                :: Element.height (Element.px <| model.window.height - 95)
                :: []
            )
            [ view model
            ]
        , footer model.route model
        ]


header : Types.LoadedModel -> Route -> { window : { width : Int, height : Int }, isCompact : Bool } -> Element Types.FrontendMsg
header model route config =
    Element.el
        [ Element.Background.color View.Color.blue
        , Element.paddingXY 24 16
        , Element.width (Element.px config.window.width)
        , Element.alignTop
        ]
        (Element.wrappedRow
            [ Element.spacing 24
            , Element.Background.color View.Color.blue
            , Element.Font.color (Element.rgb 1 1 1)
            ]
            [ Element.link
                (linkStyle route HomepageRoute)
                { url = Route.encode HomepageRoute, label = Element.text "Home" }
            , Element.link
                (linkStyle route CounterPageRoute)
                { url = Route.encode CounterPageRoute, label = Element.text "Counter" }
            ]
        )


linkStyle : Route -> Route -> List (Element.Attribute msg)
linkStyle currentRoute route =
    if currentRoute == route then
        [ Element.Font.underline, Element.Font.color View.Color.yellow ]

    else
        [ Element.Font.color View.Color.white ]


footer : Route -> Types.LoadedModel -> Element msg
footer route model =
    Element.el
        [ Element.Background.color View.Color.blue
        , Element.paddingXY 24 16
        , Element.width Element.fill
        , Element.alignBottom
        ]
        (Element.wrappedRow
            [ Element.spacing 32
            , Element.Background.color View.Color.blue
            , Element.Font.color (Element.rgb 1 1 1)
            ]
            [ Element.el [ Element.Font.color (Element.rgb 1 1 1) ] (Element.text model.message)
            ]
        )
