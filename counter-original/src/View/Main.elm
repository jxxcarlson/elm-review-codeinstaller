module View.Main exposing (view)

import Browser
import Element exposing (Element)
import Element.Background
import Element.Font
import Pages.Counter
import Pages.Home
import Pages.Notes
import Route exposing (Route(..))
import String.Extra
import Types exposing (FrontendModel(..), FrontendMsg, LoadedModel)
import View.Color


noFocus : Element.FocusStyle
noFocus =
    { borderColor = Nothing
    , backgroundColor = Nothing
    , shadow = Nothing
    }


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    { title = "Demo"
    , body =
        [ Element.layoutWith { options = [ Element.focusStyle noFocus ] }
            [ Element.width Element.fill
            , Element.Font.size 16
            , Element.Font.medium
            ]
            (case model of
                Loading _ ->
                    Element.column [ Element.width Element.fill, Element.padding 20 ]
                        [ "Loading..."
                            |> Element.text
                            |> Element.el [ Element.centerX ]
                        ]

                Loaded loaded ->
                    loadedView loaded
            )
        ]
    }


loadedView : LoadedModel -> Element FrontendMsg
loadedView model =
    case model.route of
        HomepageRoute ->
            generic model Pages.Home.view

        CounterPageRoute ->
            generic model Pages.Counter.view


generic : Types.LoadedModel -> (Types.LoadedModel -> Element Types.FrontendMsg) -> Element Types.FrontendMsg
generic model view_ =
    Element.column
        [ Element.width Element.fill, Element.height Element.fill ]
        [ Element.row [ Element.width (Element.px model.window.width), Element.Background.color View.Color.blue ]
            (headerRow model)
        , Element.column
            (Element.padding 20
                :: Element.scrollbarY
                :: Element.height (Element.px <| model.window.height - 95)
                :: []
            )
            [ view_ model
            ]
        , footer model.route model
        ]


headerRow model =
    [ headerView model model.route { window = model.window, isCompact = True } ]


headerView : Types.LoadedModel -> Route -> { window : { width : Int, height : Int }, isCompact : Bool } -> Element Types.FrontendMsg
headerView model route config =
    Element.el
        [ Element.Background.color View.Color.blue
        , Element.paddingXY 24 16
        , Element.width Element.fill
        , Element.alignTop
        ]
        (Element.wrappedRow
            [ Element.spacing 24
            , Element.Background.color View.Color.blue
            , Element.Font.color (Element.rgb 1 1 1)
            ]
            (makeLinks model route)
        )


homePageLink : Route -> Element msg
homePageLink route =
    Element.link
        (linkStyle route HomepageRoute)
        { url = Route.encode HomepageRoute, label = Element.text "Home" }


makeLink : Route -> ( Route, String ) -> Element msg
makeLink currentRoute ( route, name ) =
    Element.link
        (linkStyle currentRoute route)
        { url = Route.encode route, label = Element.text (String.Extra.toTitleCase name) }


makeLinks : Types.LoadedModel -> Route -> List (Element msg)
makeLinks model route =
    homePageLink route
        :: List.map (makeLink route) Route.routesAndNames


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
