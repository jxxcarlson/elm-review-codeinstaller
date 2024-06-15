module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import Install.ClauseInCase
import Install.FieldInTypeAlias
import Install.Function
import Install.Type
import Install.Import
import Install.Initializer
import Install.TypeVariant
import Review.Rule exposing (Rule)


config : List Rule
config =
    [
     -- TYPES
           Install.Type.makeRule "Types" "SignInState" [ "SignedOut", "SignUp", "SignedIn" ]
     -- TYPES IMPORTS
          , Install.Import.init "Types" "Auth.Common" |>Install.Import.makeRule
          , Install.Import.init "Types" "Url" |>Install.Import.makeRule
          , Install.Import.init "Types" "MagicLink.Types" |>Install.Import.makeRule
          , Install.Import.init "Types" "User" |>Install.Import.makeRule
          , Install.Import.init "Types" "Session" |>Install.Import.makeRule
          -- Type Frontend, MagicLink
          , Install.FieldInTypeAlias.makeRule "Types" "FrontendModel" "authFlow : Auth.Common.Flow"
          , Install.FieldInTypeAlias.makeRule "Types" "FrontendModel" "authRedirectBaseUrl : Url"
          , Install.FieldInTypeAlias.makeRule "Types" "FrontendModel" "signinForm : MagicLink.Types.SigninForm"
          , Install.FieldInTypeAlias.makeRule "Types" "FrontendModel" "loginErrorMessage : Maybe String"
          , Install.FieldInTypeAlias.makeRule "Types" "FrontendModel" "signInStatus : MagicLink.Types.SignInStatus"
          , Install.FieldInTypeAlias.makeRule "Types" "FrontendModel" "currentUserData : Maybe User.LoginData"
          -- Type Frontend, User
          , Install.FieldInTypeAlias.makeRule "Types" "FrontendModel" "currentUser : Maybe User.User"
          , Install.FieldInTypeAlias.makeRule "Types" "FrontendModel" "signInState : SignInState" -- Need to add this type (OR CHANGE CODE)
          , Install.FieldInTypeAlias.makeRule "Types" "FrontendModel" "realname : String"
          , Install.FieldInTypeAlias.makeRule "Types" "FrontendModel" "username : String"
          , Install.FieldInTypeAlias.makeRule "Types" "FrontendModel" "email : String"
          -- Type Backend
          , Install.FieldInTypeAlias.makeRule "Types" "BackendModel" "pendingAuths : Dict Lamdera.SessionId Auth.Common.PendingAuth"
          , Install.FieldInTypeAlias.makeRule "Types" "BackendModel" "pendingEmailAuths : Dict Lamdera.SessionId Auth.Common.PendingEmailAuth"
          , Install.FieldInTypeAlias.makeRule "Types" "BackendModel" "sessions : Dict SessionId Auth.Common.UserInfo"
          , Install.FieldInTypeAlias.makeRule "Types" "BackendModel" "secretCounter : Int"
          , Install.FieldInTypeAlias.makeRule "Types" "BackendModel" "sessionDict : AssocList.Dict SessionId String"
          , Install.FieldInTypeAlias.makeRule "Types" "BackendModel" "pendingLogins: MagicLink.Types.PendingLogins"
          , Install.FieldInTypeAlias.makeRule "Types" "BackendModel" "log : MagicLink.Types.Log"
          , Install.FieldInTypeAlias.makeRule "Types" "BackendModel" "users: Dict.Dict User.EmailString User.User"
          , Install.FieldInTypeAlias.makeRule "Types" "BackendModel" "userNameToEmailString : Dict.Dict User.Username User.EmailString"
          , Install.FieldInTypeAlias.makeRule "Types" "BackendModel" "sessionInfo : Session.SessionInfo"
          -- EXPERIMENTAL
          , Install.Type.makeRule "Frontend" "Magic" [ "Inactive", "Wizard String", "Spell String Int"]
    ]


viewFunction =
    """view model =
    Html.div [ style "padding" "50px" ]
        [ Html.button [ onClick Increment ] [ text "+" ]
        , Html.div [ style "padding" "10px" ] [ Html.text (String.fromInt model.counter) ]
        , Html.button [ onClick Decrement ] [ text "-" ]
        , Html.div [ style "padding-top" "15px", style "padding-bottom" "15px" ] [ Html.text "Click me then refresh me!" ]
        , Html.button [ onClick Reset ] [ text "Reset" ]
        ]"""


viewFunction2 =
    """view model =
     Html.div [ style "padding" "50px" ]
         [ Html.button [ onClick Increment ] [ text "+" ]
         , Html.div [ style "padding" "10px" ] [ Html.text (String.fromInt model.counter) ]
         , Html.button [ onClick Decrement ] [ text "-" ]
         , Html.div [ style "padding-top" "15px", style "padding-bottom" "15px" ] [ Html.text "Click me then refresh me!" ]
         , Html.button [ onClick Reset ] [ text "Reset" ]
         ]"""
