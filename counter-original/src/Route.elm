module Route exposing (Route(..), decode, encode)

import Url exposing (Url)
import Url.Builder
import Url.Parser


type Route
    = HomepageRoute
    | CounterPageRoute


decode : Url -> Route
decode url =
    Url.Parser.oneOf
        [ Url.Parser.top |> Url.Parser.map HomepageRoute
        , Url.Parser.s "counter" |> Url.Parser.map CounterPageRoute
        ]
        |> (\a -> Url.Parser.parse a url |> Maybe.withDefault HomepageRoute)


encode : Route -> String
encode route =
    Url.Builder.absolute
        (case route of
            HomepageRoute ->
                []

            CounterPageRoute ->
                [ "counter" ]
        )
        (case route of
            HomepageRoute ->
                []

            CounterPageRoute ->
                []
        )
