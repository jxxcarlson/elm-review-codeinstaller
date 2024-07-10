module Email exposing (EmailResult(..), PostmarkSendResponse, emailResultCodec)

import Codec
import Http


type EmailResult
    = SendingEmail
    | EmailSuccess PostmarkSendResponse
    | EmailFailed Http.Error


emailResultCodec =
    Codec.custom
        (\a b c value ->
            case value of
                SendingEmail ->
                    a

                EmailSuccess data0 ->
                    b data0

                EmailFailed data0 ->
                    c data0
        )
        |> Codec.variant0 "SendingEmail" SendingEmail
        |> Codec.variant1 "EmailSuccess" EmailSuccess postmarkSendResponseCodec
        |> Codec.variant1 "EmailFailed" EmailFailed httpErrorCodec
        |> Codec.buildCustom


postmarkSendResponseCodec =
    Codec.object PostmarkSendResponse
        |> Codec.field "to" .to Codec.string
        |> Codec.field "submittedAt" .submittedAt Codec.string
        |> Codec.field "messageId" .messageId Codec.string
        |> Codec.field "errorCode" .errorCode Codec.int
        |> Codec.field "message" .message Codec.string
        |> Codec.buildObject


httpErrorCodec =
    Codec.custom
        (\a b c d e value ->
            case value of
                Http.BadUrl data0 ->
                    a data0

                Http.Timeout ->
                    b

                Http.NetworkError ->
                    c

                Http.BadStatus int ->
                    d int

                Http.BadBody string ->
                    e string
        )
        |> Codec.variant1 "Http.BadUrl" Http.BadUrl Codec.string
        |> Codec.variant0 "Http.Timeout" Http.Timeout
        |> Codec.variant0 "Http.NetworkError" Http.NetworkError
        |> Codec.variant1 "Http.BadStatus" Http.BadStatus Codec.int
        |> Codec.variant1 "Http.BadBody" Http.BadBody Codec.string
        |> Codec.buildCustom


type alias PostmarkSendResponse =
    { to : String
    , submittedAt : String
    , messageId : String
    , errorCode : Int
    , message : String
    }
