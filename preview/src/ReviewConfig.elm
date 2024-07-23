module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import Install.ClauseInCase as ClauseInCase
import Install.ElementToList as ElementToList
import Install.FieldInTypeAlias as FieldInTypeAlias
import Install.Function.InsertFunction as InsertFunction
import Install.Function.ReplaceFunction as ReplaceFunction
import Install.Import as Import exposing (module_, qualified, withAlias, withExposedValues)
import Install.Initializer as Initializer
import Install.InitializerCmd as InitializerCmd
import Install.Subscription as Subscription
import Install.Type
import Install.TypeVariant as TypeVariant
import Regex
import Review.Rule exposing (Rule)
import String.Extra


config =
    configAll


configAll : List Rule
configAll =
    List.concat
        [ configAtmospheric
        , configUsers
        , configAuthTypes
        , configAuthFrontend
        , configAuthBackend
        , configRoute
        , newPages
        , configView
        ]


configAtmospheric : List Rule
configAtmospheric =
    [ -- Add fields randomAtmosphericNumbers and time to BackendModel
      Import.qualified "Types" [ "Http" ] |> Import.makeRule
    , Import.qualified "Backend" [ "Atmospheric", "Dict", "Time", "Task", "MagicLink.Helper", "MagicLink.Backend", "MagicLink.Auth" ] |> Import.makeRule
    , FieldInTypeAlias.makeRule "Types"
        "BackendModel"
        [ "randomAtmosphericNumbers : Maybe (List Int)"
        , "time : Time.Posix"
        ]
    , TypeVariant.makeRule "Types"
        "BackendMsg"
        [ "GotAtmosphericRandomNumbers (Result Http.Error String)"
        , "SetLocalUuidStuff (List Int)"
        , "GotFastTick Time.Posix"
        ]
    , InitializerCmd.makeRule "Backend" "init" [ "Time.now |> Task.perform GotFastTick", "MagicLink.Helper.getAtmosphericRandomNumbers" ]
    , ClauseInCase.config "Backend" "update" "GotAtmosphericRandomNumbers randomNumberString" "Atmospheric.setAtmosphericRandomNumbers model randomNumberString" |> ClauseInCase.makeRule
    , ClauseInCase.config "Backend" "update" "SetLocalUuidStuff randomInts" "(model, Cmd.none)" |> ClauseInCase.makeRule
    , ClauseInCase.config "Backend" "update" "GotFastTick time" "( { model | time = time } , Cmd.none )" |> ClauseInCase.makeRule
    ]


configUsers : List Rule
configUsers =
    [ Import.qualified "Types" [ "User" ] |> Import.makeRule
    , Import.config "Types" [ module_ "Dict" |> withExposedValues [ "Dict" ] ] |> Import.makeRule
    , FieldInTypeAlias.makeRule "Types"
        "BackendModel"
        [ "users: Dict.Dict User.EmailString User.User"
        , "userNameToEmailString : Dict.Dict User.Username User.EmailString"
        ]
    , FieldInTypeAlias.makeRule "Types" "LoadedModel" [ "users : Dict.Dict User.EmailString User.User" ]
    , Import.qualified "Backend" [ "Time", "Task", "LocalUUID" ] |> Import.makeRule
    , Import.config "Backend"
        [ module_ "MagicLink.Helper" |> withAlias "Helper"
        , module_ "Dict" |> withExposedValues [ "Dict" ]
        ]
        |> Import.makeRule
    , Import.qualified "Frontend" [ "Dict" ] |> Import.makeRule
    , Initializer.makeRule "Frontend" "initLoaded" [ { field = "users", value = "Dict.empty" } ]
    ]


configMagicLinkMinimal : List Rule
configMagicLinkMinimal =
    [ Import.qualified "Types" [ "Auth.Common", "MagicLink.Types" ] |> Import.makeRule
    , TypeVariant.makeRule "Types" "FrontendMsg" [ "AuthFrontendMsg MagicLink.Types.Msg" ]
    , TypeVariant.makeRule "Types" "BackendMsg" [ "AuthBackendMsg Auth.Common.BackendMsg" ]
    , TypeVariant.makeRule "Types" "ToBackend" [ "AuthToBackend Auth.Common.ToBackend" ]
    , FieldInTypeAlias.makeRule "Types" "LoadedModel" [ "magicLinkModel : MagicLink.Types.Model" ]
    , Import.qualified "Frontend" [ "MagicLink.Types", "Auth.Common", "MagicLink.Frontend", "MagicLink.Auth", "Pages.SignIn", "Pages.Home", "Pages.Admin", "Pages.TermsOfService", "Pages.Notes" ] |> Import.makeRule
    , Import.qualified "Backend" [ "Auth.Flow" ] |> Import.makeRule
    , Initializer.makeRule "Frontend" "initLoaded" [ { field = "magicLinkModel", value = "Pages.SignIn.init loadingModel.initUrl" } ]
    , TypeVariant.makeRule "Types"
        "ToFrontend"
        [ "AuthToFrontend Auth.Common.ToFrontend"
        , "AuthSuccess Auth.Common.UserInfo"
        , "UserInfoMsg (Maybe Auth.Common.UserInfo)"
        , "GetLoginTokenRateLimited"
        , "RegistrationError String"
        , "SignInError String"
        ]
    , ClauseInCase.config "Backend" "updateFromFrontend" "AuthToBackend authMsg" "Auth.Flow.updateFromFrontend (MagicLink.Auth.backendConfig model) clientId sessionId authMsg model" |> ClauseInCase.makeRule
    ]


configAuthTypes : List Rule
configAuthTypes =
    [ Import.qualified "Types" [ "AssocList", "Auth.Common", "LocalUUID", "MagicLink.Types", "Session" ] |> Import.makeRule
    , TypeVariant.makeRule "Types"
        "FrontendMsg"
        [ "SignInUser User.SignInData"
        , "AuthFrontendMsg MagicLink.Types.Msg"
        , "SetRoute_ Route"
        , "LiftMsg MagicLink.Types.Msg"
        ]
    , TypeVariant.makeRule "Types"
        "BackendMsg"
        [ "AuthBackendMsg Auth.Common.BackendMsg"
        , "AutoLogin SessionId User.SignInData"
        , "OnConnected SessionId ClientId"
        ]
    , FieldInTypeAlias.makeRule "Types"
        "BackendModel"
        [ "localUuidData : Maybe LocalUUID.Data"
        , "pendingAuths : Dict Lamdera.SessionId Auth.Common.PendingAuth"
        , "pendingEmailAuths : Dict Lamdera.SessionId Auth.Common.PendingEmailAuth"
        , "sessions : Dict SessionId Auth.Common.UserInfo"
        , "secretCounter : Int"
        , "sessionDict : AssocList.Dict SessionId String"
        , "pendingLogins : MagicLink.Types.PendingLogins"
        , "log : MagicLink.Types.Log"
        , "sessionInfo : Session.SessionInfo"
        ]
    , TypeVariant.makeRule "Types"
        "ToBackend"
        [ "AuthToBackend Auth.Common.ToBackend"
        , "AddUser String String String"
        , "RequestSignUp String String String"
        , "GetUserDictionary"
        ]
    , FieldInTypeAlias.makeRule "Types" "LoadedModel" [ "magicLinkModel : MagicLink.Types.Model" ]
    ]


configAuthFrontend : List Rule
configAuthFrontend =
    [ Import.qualified "Frontend" [ "MagicLink.Types", "Auth.Common", "MagicLink.Frontend", "MagicLink.Auth", "Pages.SignIn", "Pages.Home", "Pages.Admin", "Pages.TermsOfService", "Pages.Notes" ] |> Import.makeRule
    , Initializer.makeRule "Frontend" "initLoaded" [ { field = "magicLinkModel", value = "Pages.SignIn.init loadingModel.initUrl" } ]
    , ClauseInCase.config "Frontend" "updateFromBackendLoaded" "AuthToFrontend authToFrontendMsg" "MagicLink.Auth.updateFromBackend authToFrontendMsg model.magicLinkModel |> Tuple.mapFirst (\\magicLinkModel -> { model | magicLinkModel = magicLinkModel })"
        |> ClauseInCase.withInsertAtBeginning
        |> ClauseInCase.makeRule
    , ClauseInCase.config "Frontend" "updateFromBackendLoaded" "GotUserDictionary users" "( { model | users = users }, Cmd.none )"
        |> ClauseInCase.withInsertAtBeginning
        |> ClauseInCase.makeRule
    , ClauseInCase.config "Frontend" "updateFromBackendLoaded" "UserRegistered user" "MagicLink.Frontend.userRegistered model.magicLinkModel user |> Tuple.mapFirst (\\magicLinkModel -> { model | magicLinkModel = magicLinkModel })"
        |> ClauseInCase.withInsertAtBeginning
        |> ClauseInCase.makeRule
    , ClauseInCase.config "Frontend" "updateFromBackendLoaded" "GotMessage message" "({model | message = message}, Cmd.none)"
        |> ClauseInCase.withInsertAtBeginning
        |> ClauseInCase.makeRule
    , ClauseInCase.config "Frontend" "updateLoaded" "SetRoute_ route" "( { model | route = route }, Cmd.none )" |> ClauseInCase.makeRule
    , ClauseInCase.config "Frontend" "updateLoaded" "AuthFrontendMsg authToFrontendMsg" "MagicLink.Auth.update authToFrontendMsg model.magicLinkModel |> Tuple.mapFirst (\\magicLinkModel -> { model | magicLinkModel = magicLinkModel })" |> ClauseInCase.makeRule
    , ClauseInCase.config "Frontend" "updateLoaded" "SignInUser userData" "MagicLink.Frontend.signIn model userData" |> ClauseInCase.makeRule
    , TypeVariant.makeRule "Types"
        "ToFrontend"
        [ "AuthToFrontend Auth.Common.ToFrontend"
        , "AuthSuccess Auth.Common.UserInfo"
        , "UserInfoMsg (Maybe Auth.Common.UserInfo)"
        , "CheckSignInResponse (Result BackendDataStatus User.SignInData)"
        , "GetLoginTokenRateLimited"
        , "RegistrationError String"
        , "SignInError String"
        , "UserSignedIn (Maybe User.User)"
        , "UserRegistered User.User"
        , "GotUserDictionary (Dict.Dict User.EmailString User.User)"
        , "GotMessage String"
        ]
    , Install.Type.makeRule "Types" "BackendDataStatus" [ "Sunny", "LoadedBackendData", "Spell String Int" ]
    , ClauseInCase.config "Frontend" "updateLoaded" "LiftMsg _" "( model, Cmd.none )" |> ClauseInCase.makeRule
    , ReplaceFunction.config "Frontend" "tryLoading" tryLoading2
        |> ReplaceFunction.makeRule
    ]


configAuthBackend : List Rule
configAuthBackend =
    [ ClauseInCase.config "Backend" "update" "AuthBackendMsg authMsg" "Auth.Flow.backendUpdate (MagicLink.Auth.backendConfig model) authMsg" |> ClauseInCase.makeRule
    , ClauseInCase.config "Backend" "update" "AutoLogin sessionId loginData" "( model, Lamdera.sendToFrontend sessionId (AuthToFrontend <| Auth.Common.AuthSignInWithTokenResponse <| Ok <| loginData) )" |> ClauseInCase.makeRule
    , ClauseInCase.config "Backend" "update" "OnConnected sessionId clientId" "( model, Reconnect.connect model sessionId clientId )" |> ClauseInCase.makeRule
    , ClauseInCase.config "Backend" "update" "ClientConnected sessionId clientId" "( model, Reconnect.connect model sessionId clientId )" |> ClauseInCase.makeRule
    , Import.qualified "Backend"
        [ "AssocList"
        , "Auth.Common"
        , "Auth.Flow"
        , "MagicLink.Auth"
        , "MagicLink.Backend"
        , "Reconnect"
        , "User"
        ]
        |> Import.makeRule
    , Initializer.makeRule "Backend"
        "init"
        [ { field = "randomAtmosphericNumbers", value = "Just [ 235880, 700828, 253400, 602641 ]" }
        , { field = "time", value = "Time.millisToPosix 0" }
        , { field = "sessions", value = "Dict.empty" }
        , { field = "userNameToEmailString", value = "Dict.fromList [ (\"jxxcarlson\", \"jxxcarlson@gmail.com\") ]" }
        , { field = "users", value = "MagicLink.Helper.testUserDictionary" }
        , { field = "sessionInfo", value = "Dict.empty" }
        , { field = "pendingAuths", value = "Dict.empty" }
        , { field = "localUuidData", value = "LocalUUID.initFrom4List [ 235880, 700828, 253400, 602641 ]" }
        , { field = "pendingEmailAuths", value = "Dict.empty" }
        , { field = "secretCounter", value = "0" }
        , { field = "sessionDict", value = "AssocList.empty" }
        , { field = "pendingLogins", value = "AssocList.empty" }
        , { field = "log", value = "[]" }
        ]
    , ClauseInCase.config "Backend" "updateFromFrontend" "AuthToBackend authMsg" "Auth.Flow.updateFromFrontend (MagicLink.Auth.backendConfig model) clientId sessionId authMsg model" |> ClauseInCase.makeRule
    , ClauseInCase.config "Backend" "updateFromFrontend" "AddUser realname username email" "MagicLink.Backend.addUser model clientId email realname username" |> ClauseInCase.makeRule
    , ClauseInCase.config "Backend" "updateFromFrontend" "RequestSignUp realname username email" "MagicLink.Backend.requestSignUp model clientId realname username email" |> ClauseInCase.makeRule
    , ClauseInCase.config "Backend" "updateFromFrontend" "GetUserDictionary" "( model, Lamdera.sendToFrontend clientId (GotUserDictionary model.users) )" |> ClauseInCase.makeRule
    , Subscription.makeRule "Backend" [ "Lamdera.onConnect OnConnected" ]
    ]



configRoute : List Rule
configRoute =
    [ -- ROUTE
      TypeVariant.makeRule "Route" "Route" [ "NotesRoute", "SignInRoute", "AdminRoute" ]
    , ElementToList.makeRule "Route" "routesAndNames" [ "(NotesRoute, \"notes\")", "(SignInRoute, \"signin\")", "(AdminRoute, \"admin\")" ]
    ]


newPages =
    addPages [ ( "TermsOfService", "terms" ) ]


addPages : List ( String, String ) -> List Rule
addPages pageData =
    List.concatMap addPage pageData


addPage : ( String, String ) -> List Rule
addPage ( pageTitle, routeName ) =
    [ TypeVariant.makeRule "Route" "Route" [ pageTitle ++ "Route" ]
    , ClauseInCase.config "View.Main" "loadedView" (pageTitle ++ "Route") ("generic model Pages." ++ pageTitle ++ ".view") |> ClauseInCase.makeRule
    , Import.qualified "View.Main" [ "Pages." ++ pageTitle ] |> Import.makeRule
    , ElementToList.makeRule "Route" "routesAndNames" [ "(" ++ pageTitle ++ "Route, \"" ++ routeName ++ "\")" ]
    ]


configView : List Rule
configView =
    [ ClauseInCase.config "View.Main" "loadedView" "AdminRoute" adminRoute |> ClauseInCase.makeRule
    , ClauseInCase.config "View.Main" "loadedView" "NotesRoute" "generic model Pages.Notes.view" |> ClauseInCase.makeRule
    , ClauseInCase.config "View.Main" "loadedView" "SignInRoute" "generic model (\\model_ -> Pages.SignIn.view Types.LiftMsg model_.magicLinkModel |> Element.map Types.AuthFrontendMsg)" |> ClauseInCase.makeRule
    , ClauseInCase.config "View.Main" "loadedView" "CounterPageRoute" "generic model Pages.Counter.view" |> ClauseInCase.makeRule
    , Import.qualified "View.Main" [ "MagicLink.Helper", "Pages.Counter", "Pages.SignIn", "Pages.Admin", "Pages.TermsOfService", "Pages.Notes", "User" ] |> Import.makeRule
    , ReplaceFunction.config "View.Main" "headerRow" headerRow |> ReplaceFunction.makeRule
    , ReplaceFunction.config "View.Main" "makeLinks" makeLinks |> ReplaceFunction.makeRule
    ]


makeLinks =
    """makeLinks model route =
    case model.magicLinkModel.currentUserData of
        Just user ->
            homePageLink route
                :: List.map (makeLink route) (Route.routesAndNames |> List.filter (\\(r, n) -> n /= "signin") |> MagicLink.Helper.adminFilter user)


        Nothing ->
            homePageLink route
                :: List.map (makeLink route) (Route.routesAndNames |> List.filter (\\( r, n ) -> n /= "admin"))
 """


headerRow =
    """headerRow model = [ headerView model model.route { window = model.window, isCompact = True }, Pages.SignIn.showCurrentUser model |> Element.map Types.AuthFrontendMsg]"""



-- VALUES USED IN THE RULES:


adminRoute =
    "if User.isAdmin model.magicLinkModel.currentUserData then generic model Pages.Admin.view else generic model Pages.Home.view"


tryLoading2 =
    """tryLoading : LoadingModel -> ( FrontendModel, Cmd FrontendMsg )
tryLoading loadingModel =
    Maybe.map
        (\\window ->
            case loadingModel.route of
                _ ->
                    let
                        authRedirectBaseUrl =
                            let
                                initUrl =
                                    loadingModel.initUrl
                            in
                            { initUrl | query = Nothing, fragment = Nothing }
                    in
                    ( Loaded
                        { key = loadingModel.key
                        , now = loadingModel.now
                        , counter = 0
                        , window = window
                        , showTooltip = False
                        , magicLinkModel = Pages.SignIn.init authRedirectBaseUrl
                        , route = loadingModel.route
                        , message = "Starting up ..."
                        , users = Dict.empty
                        }
                    , Cmd.none
                    )
        )
        loadingModel.window
        |> Maybe.withDefault ( Loading loadingModel, Cmd.none )"""



-- Function to compress runs of spaces to a single space


asOneLine : String -> String
asOneLine str =
    str
        |> String.trim
        |> compressSpaces
        |> String.split "\n"
        |> String.join " "


compressSpaces : String -> String
compressSpaces string =
    userReplace " +" (\_ -> " ") string


userReplace : String -> (Regex.Match -> String) -> String -> String
userReplace userRegex replacer string =
    case Regex.fromString userRegex of
        Nothing ->
            string

        Just regex ->
            Regex.replace regex replacer string
