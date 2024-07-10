module View.MarkdownThemed exposing (lightTheme, renderFull)

import Element exposing (Element, centerX, el, fill, html, image, maximum, padding, px, width)
import Element.Border
import Element.Font
import Element.Region
import Html
import Html.Attributes
import Markdown.Block exposing (HeadingLevel, ListItem(..))
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer


type alias Theme =
    { defaultText : Element.Color
    , mutedText : Element.Color
    , grey : Element.Color
    , lightGrey : Element.Color
    , link : Element.Color
    }


lightTheme : Theme
lightTheme =
    { defaultText = Element.rgb255 30 50 46
    , mutedText = Element.rgb255 74 94 122
    , link = Element.rgb255 12 82 200
    , lightGrey = Element.rgb255 248 250 240
    , grey = Element.rgb255 200 220 240
    }


renderFull : String -> Element msg
renderFull markdownBody =
    render (renderer lightTheme) markdownBody


render : Markdown.Renderer.Renderer (Element msg) -> String -> Element msg
render chosenRenderer markdownBody =
    Markdown.Parser.parse markdownBody
        -- @TODO show markdown parsing errors, i.e. malformed html?
        |> Result.withDefault []
        |> (\parsed ->
                parsed
                    |> Markdown.Renderer.render chosenRenderer
                    |> (\res ->
                            case res of
                                Ok elements ->
                                    elements

                                Err err ->
                                    [ Element.text "Something went wrong rendering this page"
                                    , Element.text err
                                    ]
                       )
                    |> Element.column
                        [ Element.width Element.fill
                        ]
           )


renderer : Theme -> Markdown.Renderer.Renderer (Element msg)
renderer theme =
    { heading = \data -> Element.row [] [ heading theme data ]
    , paragraph = Element.paragraph [ Element.paddingEach { left = 0, right = 0, top = 0, bottom = 20 } ]
    , blockQuote =
        \children ->
            Element.column
                [ Element.Font.size 20
                , Element.Font.italic
                , Element.Border.widthEach { bottom = 0, left = 4, right = 0, top = 0 }
                , Element.Border.color theme.grey
                , Element.Font.color theme.mutedText
                , Element.padding 10
                ]
                children
    , html =
        Markdown.Html.oneOf
            [ Markdown.Html.tag "img"
                (\src width_ maxWidth_ bg_ content ->
                    let
                        attrs =
                            case maxWidth_ of
                                Just maxWidth ->
                                    [ maxWidth
                                        |> String.toInt
                                        |> Maybe.map (\w -> width (fill |> maximum w))
                                        |> Maybe.withDefault (width fill)
                                    , centerX
                                    ]

                                Nothing ->
                                    [ width_
                                        |> Maybe.andThen String.toInt
                                        |> Maybe.map (\w -> width (px w))
                                        |> Maybe.withDefault (width fill)
                                    ]
                    in
                    case bg_ of
                        Just bg ->
                            el [ Element.Border.rounded 10, padding 20 ] <| image attrs { src = src, description = "" }

                        Nothing ->
                            image attrs { src = src, description = "" }
                )
                |> Markdown.Html.withAttribute "src"
                |> Markdown.Html.withOptionalAttribute "width"
                |> Markdown.Html.withOptionalAttribute "maxwidth"
                |> Markdown.Html.withOptionalAttribute "bg"
            , Markdown.Html.tag "br" (\_ -> html <| Html.br [] [])
            ]
    , text = \s -> Element.el [] (Element.text s)
    , codeSpan =
        \content -> Element.html (Html.code [ Html.Attributes.style "color" "#220cb0" ] [ Html.text content ])
    , strong = \list -> Element.paragraph [ Element.Font.bold ] list
    , emphasis = \list -> Element.paragraph [ Element.Font.italic ] list
    , hardLineBreak = Element.html (Html.br [] [])
    , link =
        \{ title, destination } list ->
            Element.link
                [ Element.Font.underline
                , Element.Font.color theme.link
                ]
                { url = destination
                , label =
                    case title of
                        Just title_ ->
                            Element.text title_

                        Nothing ->
                            Element.paragraph [] list
                }
    , image =
        \{ alt, src, title } ->
            let
                attrs =
                    [ title |> Maybe.map (\title_ -> Element.htmlAttribute (Html.Attributes.attribute "title" title_)) ]
                        |> justs
            in
            Element.image
                attrs
                { src = src
                , description = alt
                }
    , unorderedList =
        \items ->
            Element.column
                [ Element.spacing 15
                , Element.width Element.fill
                , Element.paddingEach { top = 0, right = 0, bottom = 40, left = 0 }
                ]
                (items
                    |> List.map
                        (\listItem ->
                            case listItem of
                                ListItem _ children ->
                                    Element.wrappedRow
                                        [ Element.spacing 5
                                        , Element.paddingEach { top = 0, right = 0, bottom = 0, left = 20 }
                                        , Element.width Element.fill
                                        ]
                                        [ Element.paragraph
                                            [ Element.alignTop ]
                                            (Element.text " • " :: children)
                                        ]
                        )
                )
    , orderedList =
        \startingIndex items ->
            Element.column [ Element.spacing 15, Element.width Element.fill ]
                (items
                    |> List.indexedMap
                        (\index itemBlocks ->
                            Element.wrappedRow
                                [ Element.spacing 5
                                , Element.paddingEach { top = 0, right = 0, bottom = 0, left = 20 }
                                , Element.width Element.fill
                                ]
                                [ Element.paragraph
                                    [ Element.alignTop ]
                                    (Element.text (String.fromInt (startingIndex + index) ++ ". ") :: itemBlocks)
                                ]
                        )
                )
    , codeBlock =
        \{ body } ->
            let
                numberOfLines =
                    String.lines body
                        |> List.length
                        |> toFloat
                        |> (\x -> 1.35 * x)
                        |> round
            in
            Element.column
                [ Element.Font.family [ Element.Font.monospace ]
                , Element.Font.size 14
                , Element.Font.color (Element.rgb255 34 12 176)
                , Element.Border.rounded 5
                , Element.paddingEach { left = 0, right = 0, top = 8, bottom = 20 }
                , Element.width Element.fill
                , Element.height (Element.px <| 16 * numberOfLines + 24)
                , Element.htmlAttribute (Html.Attributes.class "preserve-white-space")
                , Element.htmlAttribute (Html.Attributes.style "line-height" "1.4")
                , Element.scrollbarX
                ]
                [ Element.html (Html.text body) ]
    , thematicBreak = Element.none
    , table = \children -> Element.column [ Element.width Element.fill ] children
    , tableHeader = \children -> Element.column [] children
    , tableBody = \children -> Element.column [] children
    , tableRow = \children -> Element.row [ Element.width Element.fill ] children
    , tableCell = \_ children -> Element.column [ Element.width Element.fill ] children
    , tableHeaderCell = \_ children -> Element.column [ Element.width Element.fill ] children
    , strikethrough = \children -> Element.paragraph [ Element.Font.strike ] children
    }


heading1 : List (Element.Attr () msg)
heading1 =
    [ Element.Font.size 36
    , Element.Font.semiBold
    , Element.Font.color lightTheme.defaultText
    , Element.paddingEach { top = 40, right = 0, bottom = 30, left = 0 }
    ]


heading : Theme -> { level : HeadingLevel, rawText : String, children : List (Element msg) } -> Element msg
heading theme { level, rawText, children } =
    Element.paragraph
        ((case Markdown.Block.headingLevelToInt level of
            1 ->
                heading1

            2 ->
                [ Element.Font.color theme.defaultText
                , Element.Font.size 28
                , Element.Font.semiBold
                , Element.paddingEach { top = 20, right = 0, bottom = 20, left = 0 }
                ]

            3 ->
                [ Element.Font.color theme.defaultText
                , Element.Font.size 20
                , Element.Font.semiBold

                --, Element.Font.medium
                , Element.paddingEach { top = 10, right = 0, bottom = 10, left = 0 }
                ]

            4 ->
                [ Element.Font.color theme.defaultText
                , Element.Font.size 16
                , Element.Font.medium
                , Element.paddingEach { top = 0, right = 0, bottom = 10, left = 0 }
                ]

            _ ->
                [ Element.Font.size 12
                , Element.Font.medium
                , Element.Font.center
                , Element.paddingXY 0 20
                ]
         )
            ++ [ Element.Region.heading (Markdown.Block.headingLevelToInt level)
               , Element.htmlAttribute
                    (Html.Attributes.attribute "name" (rawTextToId rawText))
               , Element.htmlAttribute
                    (Html.Attributes.id (rawTextToId rawText))
               ]
        )
        children


rawTextToId : String -> String
rawTextToId rawText =
    rawText
        |> String.toLower
        |> String.replace " " "-"
        |> String.replace "." ""


justs : List (Maybe a) -> List a
justs =
    List.foldl
        (\v acc ->
            case v of
                Just el ->
                    el :: acc

                Nothing ->
                    acc
        )
        []
