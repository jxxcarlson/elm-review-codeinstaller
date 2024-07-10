module Unsafe exposing (emailAddress, name, url)

import EmailAddress exposing (EmailAddress)
import Name exposing (Name)
import Url exposing (Url)


name : String -> Name
name text =
    case Name.fromString text of
        Ok ok ->
            ok

        Err _ ->
            unreachable ()


emailAddress : String -> EmailAddress
emailAddress text =
    case EmailAddress.fromString text of
        Just ok ->
            ok

        Nothing ->
            unreachable ()


url : String -> Url
url urlText =
    case Url.fromString urlText of
        Just url_ ->
            url_

        Nothing ->
            unreachable ()


{-| Be very careful when using this!
-}
unreachable : () -> a
unreachable () =
    unreachable ()
