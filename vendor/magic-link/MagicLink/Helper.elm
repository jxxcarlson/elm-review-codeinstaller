module MagicLink.Helper exposing
    ( adminFilter
    , getAtmosphericRandomNumbers
    , initialUserDictionary
    , trigger
    )

import Dict
import EmailAddress
import Http
import LocalUUID
import Task
import Time
import Types
import User



-- MAGICLINK
-- TODO: this is a hack based on a lack of understanding of what is going on.
-- in Martin's code.
-- OTHER


trigger : msg -> Cmd msg
trigger msg =
    Task.perform (always msg) Time.now


initialUserDictionary : { fullname : String, username : String, email : String } -> Dict.Dict User.EmailString User.User
initialUserDictionary { fullname, username, email } =
    case getParts email of
        Just parts ->
            Dict.fromList
                [ ( email
                  , { fullname = fullname
                    , username = username
                    , email = EmailAddress.EmailAddress { domain = parts.emailDomain, localPart = parts.emailLocalPart, tags = [], tld = parts.emailTld }
                    , emailString = email
                    , id = "661b76d8-eee8-42fb-a28d-cf8ada73f869"
                    , created_at = Time.millisToPosix 1704237963000
                    , updated_at = Time.millisToPosix 1704237963000
                    , roles = [ User.AdminRole, User.UserRole ]
                    , recentLoginEmails = []
                    , verified = Nothing
                    }
                  )
                ]

        Nothing ->
            Dict.empty


getParts : String -> Maybe { emailDomain : String, emailLocalPart : String, emailTld : List String }
getParts str =
    case String.split "@" str of
        [ localPart, domain ] ->
            case String.split "." domain of
                emailDomain :: rest ->
                    Just { emailDomain = emailDomain, emailLocalPart = localPart, emailTld = rest } |> Debug.log "XX, STUFF"

                _ ->
                    Nothing

        _ ->
            Nothing


adminFilter user =
    if not <| List.member User.AdminRole user.roles then
        List.filter (\( r, n ) -> n /= "admin")

    else
        identity


getAtmosphericRandomNumbers : Cmd Types.BackendMsg
getAtmosphericRandomNumbers =
    Http.get
        { url = LocalUUID.randomNumberUrl 4 9
        , expect = Http.expectString Types.GotAtmosphericRandomNumbers
        }
