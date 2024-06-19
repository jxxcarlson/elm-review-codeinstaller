module View.Main exposing (view)

import Browser
import Element exposing (Element)
import Element.Font
import Pages.Counter
import Pages.Home
import Pages.Parts
import Route exposing (Route(..))
import Types exposing (FrontendModel(..), FrontendMsg, LoadedModel)


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
            Pages.Parts.generic model Pages.Home.view

        CounterPageRoute ->
            Pages.Parts.generic model Pages.Counter.view
