module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import Install
import Install.ClauseInCase as ClauseInCase
import Install.ElementToList as ElementToList
import Install.FieldInTypeAlias as FieldInTypeAlias
import Install.Function.ReplaceFunction as ReplaceFunction
import Install.Import as Import exposing (module_, withAlias, withExposedValues)
import Install.Initializer as Initializer
import Install.InitializerCmd as InitializerCmd
import Install.Subscription as Subscription
import Install.Type
import Install.TypeVariant as TypeVariant
import Regex
import Review.Rule exposing (Rule)
import String.Extra


config =
    configMagicLinkAuth "Jim Carlson" "jxxcarlson" "jxxcarlson@gmail.com"


configMagicLinkAuth fullname username email =
    configAll { fullname = fullname, username = username, email = email }


stringifyAdminConfig : { fullname : String, username : String, email : String } -> String
stringifyAdminConfig { fullname, username, email } =
    "{ fullname = " ++ String.Extra.quote fullname ++ ", username = " ++ String.Extra.quote username ++ ", email = " ++ String.Extra.quote email ++ "}"


configAll : { fullname : String, username : String, email : String } -> List Rule
configAll adminConfig =
    [ configAtmospheric
    , configUsers
    , configAuthTypes
    , configAuthFrontend
    , configAuthBackend adminConfig
    , configRoute
    , newPages
    , configView
    ]


configAtmospheric : Rule
configAtmospheric =
    Install.rule "AddAtmospheric"
        [ -- Add fields randomAtmosphericNumbers and time to BackendModel
          Import.qualified "Types" [ "Http" ]
            |> Install.imports
        , Import.qualified "Backend" [ "Atmospheric", "Dict", "Time", "Task", "MagicLink.Helper", "MagicLink.Backend", "MagicLink.Auth" ]
            |> Install.imports
        , ClauseInCase.config "Backend" "update" "GotAtmosphericRandomNumbers randomNumberString" "Atmospheric.setAtmosphericRandomNumbers model randomNumberString"
            |> Install.clauseInCase
        , ClauseInCase.config "Backend" "update" "SetLocalUuidStuff randomInts" "(model, Cmd.none)"
            |> Install.clauseInCase
        , ClauseInCase.config "Backend" "update" "GotFastTick time" "( { model | time = time } , Cmd.none )"
            |> Install.clauseInCase
        , FieldInTypeAlias.config "Types"
            "BackendModel"
            [ "randomAtmosphericNumbers : Maybe (List Int)"
            , "time : Time.Posix"
            ]
            |> Install.insertFieldInTypeAlias
        , InitializerCmd.config "Backend" "init" [ "Time.now |> Task.perform GotFastTick", "MagicLink.Helper.getAtmosphericRandomNumbers" ]
            |> Install.initializerCmd
        , TypeVariant.config "Types"
            "BackendMsg"
            [ "GotAtmosphericRandomNumbers (Result Http.Error String)"
            , "SetLocalUuidStuff (List Int)"
            , "GotFastTick Time.Posix"
            ]
            |> Install.addTypeVariant
        ]


configUsers : Rule
configUsers =
    Install.rule "ConfigUsers"
        [ Import.qualified "Types" [ "User" ]
            |> Install.imports
        , Import.config "Types" [ module_ "Dict" |> withExposedValues [ "Dict" ] ]
            |> Install.imports
        , Import.qualified "Backend" [ "Time", "Task", "LocalUUID" ]
            |> Install.imports
        , Import.config "Backend"
            [ module_ "MagicLink.Helper" |> withAlias "Helper"
            , module_ "Dict" |> withExposedValues [ "Dict" ]
            ]
            |> Install.imports
        , Import.qualified "Frontend" [ "Dict" ]
            |> Install.imports
        , FieldInTypeAlias.config "Types"
            "BackendModel"
            [ "users: Dict.Dict User.EmailString User.User"
            , "userNameToEmailString : Dict.Dict User.Username User.EmailString"
            ]
            |> Install.insertFieldInTypeAlias
        , FieldInTypeAlias.config "Types" "LoadedModel" [ "users : Dict.Dict User.EmailString User.User" ]
            |> Install.insertFieldInTypeAlias
        , Initializer.config "Frontend" "initLoaded" [ { field = "users", value = "Dict.empty" } ]
            |> Install.initializer
        ]


configMagicLinkMinimal : Rule
configMagicLinkMinimal =
    Install.rule "AddMagicLink"
        [ Import.qualified "Types" [ "Auth.Common", "MagicLink.Types" ]
            |> Install.imports
        , Import.qualified "Frontend" [ "MagicLink.Types", "Auth.Common", "MagicLink.Frontend", "MagicLink.Auth", "Pages.SignIn", "Pages.Home", "Pages.Admin", "Pages.TermsOfService", "Pages.Notes" ]
            |> Install.imports
        , Import.qualified "Backend" [ "Auth.Flow" ]
            |> Install.imports
        , ClauseInCase.config "Backend" "updateFromFrontend" "AuthToBackend authMsg" "Auth.Flow.updateFromFrontend (MagicLink.Auth.backendConfig model) clientId sessionId authMsg model"
            |> Install.clauseInCase
        , FieldInTypeAlias.config "Types" "LoadedModel" [ "magicLinkModel : MagicLink.Types.Model" ]
            |> Install.insertFieldInTypeAlias
        , Initializer.config "Frontend" "initLoaded" [ { field = "magicLinkModel", value = "Pages.SignIn.init loadingModel.initUrl" } ]
            |> Install.initializer
        , TypeVariant.config "Types" "FrontendMsg" [ "AuthFrontendMsg MagicLink.Types.Msg" ]
            |> Install.addTypeVariant
        , TypeVariant.config "Types" "BackendMsg" [ "AuthBackendMsg Auth.Common.BackendMsg" ]
            |> Install.addTypeVariant
        , TypeVariant.config "Types" "ToBackend" [ "AuthToBackend Auth.Common.ToBackend" ]
            |> Install.addTypeVariant
        , TypeVariant.config "Types"
            "ToFrontend"
            [ "AuthToFrontend Auth.Common.ToFrontend"
            , "AuthSuccess Auth.Common.UserInfo"
            , "UserInfoMsg (Maybe Auth.Common.UserInfo)"
            , "GetLoginTokenRateLimited"
            , "RegistrationError String"
            , "SignInError String"
            ]
            |> Install.addTypeVariant
        ]


configAuthTypes : Rule
configAuthTypes =
    Install.rule "ConfigAuth"
        [ Import.qualified "Types" [ "AssocList", "Auth.Common", "LocalUUID", "MagicLink.Types", "Session" ]
            |> Install.imports
        , FieldInTypeAlias.config "Types"
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
            |> Install.insertFieldInTypeAlias
        , FieldInTypeAlias.config "Types" "LoadedModel" [ "magicLinkModel : MagicLink.Types.Model" ]
            |> Install.insertFieldInTypeAlias
        , TypeVariant.config "Types"
            "FrontendMsg"
            [ "SignInUser User.SignInData"
            , "AuthFrontendMsg MagicLink.Types.Msg"
            , "SetRoute_ Route"
            , "LiftMsg MagicLink.Types.Msg"
            ]
            |> Install.addTypeVariant
        , TypeVariant.config "Types"
            "BackendMsg"
            [ "AuthBackendMsg Auth.Common.BackendMsg"
            , "AutoLogin SessionId User.SignInData"
            , "OnConnected SessionId ClientId"
            ]
            |> Install.addTypeVariant
        , TypeVariant.config "Types"
            "ToBackend"
            [ "AuthToBackend Auth.Common.ToBackend"
            , "AddUser String String String"
            , "RequestSignUp String String String"
            , "GetUserDictionary"
            ]
            |> Install.addTypeVariant
        ]


configAuthFrontend : Rule
configAuthFrontend =
    Install.rule "ConfigAuthFrontend"
        [ Import.qualified "Frontend" [ "MagicLink.Types", "Auth.Common", "MagicLink.Frontend", "MagicLink.Auth", "Pages.SignIn", "Pages.Home", "Pages.Admin", "Pages.TermsOfService", "Pages.Notes" ]
            |> Install.imports
        , ReplaceFunction.config "Frontend" "tryLoading" tryLoading2
            |> Install.replaceFunction
        , ClauseInCase.config "Frontend" "updateFromBackendLoaded" "AuthToFrontend authToFrontendMsg" "MagicLink.Auth.updateFromBackend authToFrontendMsg model.magicLinkModel |> Tuple.mapFirst (\\magicLinkModel -> { model | magicLinkModel = magicLinkModel })"
            |> ClauseInCase.withInsertAtBeginning
            |> Install.clauseInCase
        , ClauseInCase.config "Frontend" "updateFromBackendLoaded" "GotUserDictionary users" "( { model | users = users }, Cmd.none )"
            |> ClauseInCase.withInsertAtBeginning
            |> Install.clauseInCase
        , ClauseInCase.config "Frontend" "updateFromBackendLoaded" "UserRegistered user" "MagicLink.Frontend.userRegistered model.magicLinkModel user |> Tuple.mapFirst (\\magicLinkModel -> { model | magicLinkModel = magicLinkModel })"
            |> ClauseInCase.withInsertAtBeginning
            |> Install.clauseInCase
        , ClauseInCase.config "Frontend" "updateFromBackendLoaded" "GotMessage message" "({model | message = message}, Cmd.none)"
            |> ClauseInCase.withInsertAtBeginning
            |> Install.clauseInCase
        , ClauseInCase.config "Frontend" "updateLoaded" "SetRoute_ route" "( { model | route = route }, Cmd.none )"
            |> Install.clauseInCase
        , ClauseInCase.config "Frontend" "updateLoaded" "AuthFrontendMsg authToFrontendMsg" "MagicLink.Auth.update authToFrontendMsg model.magicLinkModel |> Tuple.mapFirst (\\magicLinkModel -> { model | magicLinkModel = magicLinkModel })"
            |> Install.clauseInCase
        , ClauseInCase.config "Frontend" "updateLoaded" "SignInUser userData" "MagicLink.Frontend.signIn model userData"
            |> Install.clauseInCase
        , ClauseInCase.config "Frontend" "updateLoaded" "LiftMsg _" "( model, Cmd.none )"
            |> Install.clauseInCase
        , Initializer.config "Frontend" "initLoaded" [ { field = "magicLinkModel", value = "Pages.SignIn.init loadingModel.initUrl" } ]
            |> Install.initializer
        , Install.Type.config "Types" "BackendDataStatus" [ "Sunny", "LoadedBackendData", "Spell String Int" ]
            |> Install.addType
        , TypeVariant.config "Types"
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
            |> Install.addTypeVariant
        ]


configAuthBackend : { fullname : String, username : String, email : String } -> Rule
configAuthBackend adminConfig =
    Install.rule "ConfigAuthBackend"
        [ ClauseInCase.config "Backend" "update" "AuthBackendMsg authMsg" "Auth.Flow.backendUpdate (MagicLink.Auth.backendConfig model) authMsg"
            |> Install.clauseInCase
        , ClauseInCase.config "Backend" "update" "AutoLogin sessionId loginData" "( model, Lamdera.sendToFrontend sessionId (AuthToFrontend <| Auth.Common.AuthSignInWithTokenResponse <| Ok <| loginData) )"
            |> Install.clauseInCase
        , ClauseInCase.config "Backend" "update" "OnConnected sessionId clientId" "( model, Reconnect.connect model sessionId clientId )"
            |> Install.clauseInCase
        , ClauseInCase.config "Backend" "update" "ClientConnected sessionId clientId" "( model, Reconnect.connect model sessionId clientId )"
            |> Install.clauseInCase
        , Import.qualified "Backend"
            [ "AssocList"
            , "Auth.Common"
            , "Auth.Flow"
            , "MagicLink.Auth"
            , "MagicLink.Backend"
            , "Reconnect"
            , "User"
            ]
            |> Install.imports
        , ClauseInCase.config "Backend" "updateFromFrontend" "AuthToBackend authMsg" "Auth.Flow.updateFromFrontend (MagicLink.Auth.backendConfig model) clientId sessionId authMsg model"
            |> Install.clauseInCase
        , ClauseInCase.config "Backend" "updateFromFrontend" "AddUser realname username email" "MagicLink.Backend.addUser model clientId email realname username"
            |> Install.clauseInCase
        , ClauseInCase.config "Backend" "updateFromFrontend" "RequestSignUp realname username email" "MagicLink.Backend.requestSignUp model clientId realname username email"
            |> Install.clauseInCase
        , ClauseInCase.config "Backend" "updateFromFrontend" "GetUserDictionary" "( model, Lamdera.sendToFrontend clientId (GotUserDictionary model.users) )"
            |> Install.clauseInCase
        , Initializer.config "Backend"
            "init"
            [ { field = "randomAtmosphericNumbers", value = "Just [ 235880, 700828, 253400, 602641 ]" }
            , { field = "time", value = "Time.millisToPosix 0" }
            , { field = "sessions", value = "Dict.empty" }
            , { field = "userNameToEmailString", value = "Dict.fromList [ (\"jxxcarlson\", \"jxxcarlson@gmail.com\") ]" }
            , { field = "users", value = "MagicLink.Helper.initialUserDictionary " ++ stringifyAdminConfig adminConfig }
            , { field = "sessionInfo", value = "Dict.empty" }
            , { field = "pendingAuths", value = "Dict.empty" }
            , { field = "localUuidData", value = "LocalUUID.initFrom4List [ 235880, 700828, 253400, 602641 ]" }
            , { field = "pendingEmailAuths", value = "Dict.empty" }
            , { field = "secretCounter", value = "0" }
            , { field = "sessionDict", value = "AssocList.empty" }
            , { field = "pendingLogins", value = "AssocList.empty" }
            , { field = "log", value = "[]" }
            ]
            |> Install.initializer
        , Subscription.config "Backend" [ "Lamdera.onConnect OnConnected" ]
            |> Install.subscription
        ]


configRoute : Rule
configRoute =
    Install.rule "AddRoute"
        [ -- ROUTE
          TypeVariant.config "Route" "Route" [ "NotesRoute", "SignInRoute", "AdminRoute" ]
            |> Install.addTypeVariant
        , ElementToList.config
            "Route"
            "routesAndNames"
            [ "(NotesRoute, \"notes\")", "(SignInRoute, \"signin\")", "(AdminRoute, \"admin\")" ]
            |> Install.addElementToList
        ]


newPages : Rule
newPages =
    Install.rule "AddPage"
        (List.concatMap addPage [ ( "TermsOfService", "terms" ) ])


addPage : ( String, String ) -> List Install.Installation
addPage ( pageTitle, routeName ) =
    [ TypeVariant.config "Route" "Route" [ pageTitle ++ "Route" ]
        |> Install.addTypeVariant
    , ClauseInCase.config "View.Main" "loadedView" (pageTitle ++ "Route") ("generic model Pages." ++ pageTitle ++ ".view")
        |> Install.clauseInCase
    , Import.qualified "View.Main" [ "Pages." ++ pageTitle ]
        |> Install.imports
    , ElementToList.config
        "Route"
        "routesAndNames"
        [ "(" ++ pageTitle ++ "Route, \"" ++ routeName ++ "\")" ]
        |> Install.addElementToList
    ]


configView : Rule
configView =
    Install.rule "AddConfig"
        [ ClauseInCase.config "View.Main" "loadedView" "AdminRoute" adminRoute
            |> Install.clauseInCase
        , ClauseInCase.config "View.Main" "loadedView" "NotesRoute" "generic model Pages.Notes.view"
            |> Install.clauseInCase
        , ClauseInCase.config "View.Main" "loadedView" "SignInRoute" "generic model (\\model_ -> Pages.SignIn.view Types.LiftMsg model_.magicLinkModel |> Element.map Types.AuthFrontendMsg)"
            |> Install.clauseInCase
        , ClauseInCase.config "View.Main" "loadedView" "CounterPageRoute" "generic model Pages.Counter.view"
            |> Install.clauseInCase
        , Import.qualified "View.Main" [ "MagicLink.Helper", "Pages.Counter", "Pages.SignIn", "Pages.Admin", "Pages.TermsOfService", "Pages.Notes", "User" ]
            |> Install.imports
        , ReplaceFunction.config "View.Main" "headerRow" headerRow
            |> Install.replaceFunction
        , ReplaceFunction.config "View.Main" "makeLinks" makeLinks
            |> Install.replaceFunction
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
