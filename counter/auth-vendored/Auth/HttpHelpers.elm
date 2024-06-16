module Auth.HttpHelpers exposing (customError, expectJson, httpErrorToString, jsonResolver, parseError)

import Http
import Json.Decode as D


{-| The default Http.expectJson / Http.expectString don't allow you to see any body
returned in an error (i.e. 403) states. The following docs;
<https://package.elm-lang.org/packages/elm/http/latest/Http#expectStringResponse>
describe our sitution perfectly, so that's that code below, with a modified
Http.BadStatus\_ handler to map it to BadBody String instead of BadStatus Int
so we can actually see the error message.
-}
expectJson : (Result Http.Error a -> msg) -> D.Decoder a -> Http.Expect msg
expectJson toMsg decoder =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ metadata body ->
                    Err (Http.BadBody (String.fromInt metadata.statusCode ++ ": " ++ body))

                Http.GoodStatus_ metadata body ->
                    case D.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            Err (Http.BadBody (D.errorToString err))



-- From https://github.com/krisajenkins/remotedata/issues/28


parseError : String -> Maybe String
parseError =
    D.decodeString (D.field "error" D.string) >> Result.toMaybe


httpErrorToString : Http.Error -> String
httpErrorToString err =
    case err of
        Http.BadUrl url ->
            "HTTP malformed url: " ++ url

        Http.Timeout ->
            "HTTP timeout exceeded"

        Http.NetworkError ->
            "HTTP network error"

        Http.BadStatus code ->
            "Unexpected HTTP response code: " ++ String.fromInt code

        Http.BadBody text ->
            "HTTP error: " ++ text



-- httpErrorToStringEffect : Effect.Http.Error -> String
-- httpErrorToStringEffect err =
--     case err of
--         Effect.Http.BadUrl url ->
--             "HTTP malformed url: " ++ url
--
--         Effect.Http.Timeout ->
--             "HTTP timeout exceeded"
--
--         Effect.Http.NetworkError ->
--             "HTTP network error"
--
--         Effect.Http.BadStatus code ->
--             "Unexpected HTTP response code: " ++ String.fromInt code
--
--         Effect.Http.BadBody text ->
--             "HTTP error: " ++ text


customError : String -> Http.Error
customError s =
    Http.BadBody <| "Error: " ++ s



-- customErrorEffect : String -> Effect.Http.Error
-- customErrorEffect s =
--     Effect.Http.BadBody <| "Error: " ++ s


jsonResolver : D.Decoder a -> Http.Resolver Http.Error a
jsonResolver decoder =
    Http.stringResolver <|
        \response ->
            case response of
                Http.GoodStatus_ _ body ->
                    D.decodeString decoder body
                        |> Result.mapError D.errorToString
                        |> Result.mapError Http.BadBody

                Http.BadUrl_ message ->
                    Err (Http.BadUrl message)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ metadata body ->
                    Err (Http.BadBody (String.fromInt metadata.statusCode ++ ": " ++ body))



-- jsonResolverEffect : D.Decoder a -> Effect.Http.Resolver restriction Effect.Http.Error a
-- jsonResolverEffect decoder =
--     Effect.Http.stringResolver <|
--         \response ->
--             case response of
--                 Effect.Http.GoodStatus_ _ body ->
--                     D.decodeString decoder body
--                         |> Result.mapError D.errorToString
--                         |> Result.mapError Effect.Http.BadBody
--
--                 Effect.Http.BadUrl_ message ->
--                     Err (Effect.Http.BadUrl message)
--
--                 Effect.Http.Timeout_ ->
--                     Err Effect.Http.Timeout
--
--                 Effect.Http.NetworkError_ ->
--                     Err Effect.Http.NetworkError
--
--                 Effect.Http.BadStatus_ metadata body ->
--                     Err (Effect.Http.BadBody (String.fromInt metadata.statusCode ++ ": " ++ body))
