                                                                                                                                                                             module User exposing
    ( EmailString
    , Id
    , LoginData
    , Role(..)
    , User
    , Username
    , loginDataOfUser
    , setAsVerified
    )

import Dict
import EmailAddress exposing (EmailAddress)
import Time


type alias User =
    { id : String
    , fullname : String
    , username : String
    , email : EmailAddress
    , emailString : EmailString
    , created_at : Time.Posix
    , updated_at : Time.Posix
    , roles : List Role
    , verified : Maybe Time.Posix
    , recentLoginEmails : List Time.Posix
    }


verifyNow : Time.Posix -> User -> User
verifyNow now user =
    case user.verified of
        Just _ ->
            user

        Nothing ->
            { user | verified = Just now }


setAsVerified : Time.Posix -> User -> Dict.Dict EmailString User -> Dict.Dict EmailString User
setAsVerified now user users =
    Dict.insert user.emailString (verifyNow now user) users


type alias Username =
    String


type alias EmailString =
    String


type alias LoginData =
    { username : String
    , email : EmailString
    , name : String
    , roles : List Role
    }


loginDataOfUser : User -> LoginData
loginDataOfUser user =
    { username = user.username
    , roles = user.roles
    , name = user.fullname
    , email = user.emailString
    }


type Role
    = AdminRole
    | UserRole


type alias Id =
    String
