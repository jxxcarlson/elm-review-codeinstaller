module EmailViewer exposing (main)

import Email.Html
import Html exposing (Html)
import Html.Attributes
import RPC
import String.Nonempty exposing (NonemptyString)


main =
    [ emailView (RPC.confirmationEmail Tickets.campTicket)
    ]
        |> List.intersperse spacing
        |> Html.div []


spacing : Html msg
spacing =
    Html.div [ Html.Attributes.style "padding" "32px" ] []


emailView : { subject : NonemptyString, htmlBody : Email.Html.Html, textBody : String } -> Html msg
emailView { subject, htmlBody, textBody } =
    Html.div
        []
        [ Html.div
            [ Html.Attributes.style "padding" "8px" ]
            [ Html.b [] [ Html.text (String.Nonempty.toString subject) ] ]
        , Html.div
            [ Html.Attributes.style "padding" "8px"
            , Html.Attributes.style "white-space" "pre-wrap"
            ]
            [ Html.text textBody ]
        , Html.div [ Html.Attributes.style "border" "1px solid black" ] [ Email.Html.toHtml htmlBody ]
        ]
