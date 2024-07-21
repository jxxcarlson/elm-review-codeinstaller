module Route exposing (Route(..), decode, encode, routesAndNames)

import List.Extra
import Url exposing (Url)
import Url.Builder
import Url.Parser


type Route
    = HomepageRoute
    | CounterPageRoute


routesAndNames : List ( Route, String )
routesAndNames =
    [ ( CounterPageRoute, "counter" ) ]


encodeRoute : Route -> List String
encodeRoute route =
    List.Extra.find (\( r, _ ) -> r == route) routesAndNames
        |> Maybe.map Tuple.second
        |> Maybe.map (\name -> [ name ])
        |> Maybe.withDefault []


decode : Url -> Route
decode url =
    Url.Parser.oneOf
        ((Url.Parser.top |> Url.Parser.map HomepageRoute) :: parserData)
        |> (\a -> Url.Parser.parse a url |> Maybe.withDefault HomepageRoute)


encode : Route -> String
encode route =
    Url.Builder.absolute
        (encodeRoute route)
        []


parserData : List (Url.Parser.Parser (Route -> c) c)
parserData =
    List.map (\( route, name ) -> Url.Parser.s name |> Url.Parser.map route) routesAndNames
