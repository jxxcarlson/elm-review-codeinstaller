module MagicLink.Helper exposing
    ( adminFilter
    , getAtmosphericRandomNumbers
    , testUserDictionary
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


testUserDictionary : Dict.Dict User.EmailString User.User
testUserDictionary =
    Dict.fromList
        [ ( "jxxcarlson@gmail.com"
          , { fullname = "Jim Carlson"
            , username = "jxxcarlson"
            , email = EmailAddress.EmailAddress { domain = "gmail", localPart = "jxxcarlson", tags = [], tld = [ "com" ] }
            , emailString = "jxxcarlson@gmail.com"
            , id = "661b76d8-eee8-42fb-a28d-cf8ada73f869"
            , created_at = Time.millisToPosix 1704237963000
            , updated_at = Time.millisToPosix 1704237963000
            , roles = [ User.AdminRole, User.UserRole ]
            , recentLoginEmails = []
            , verified = Nothing
            }
          )
        ]


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
