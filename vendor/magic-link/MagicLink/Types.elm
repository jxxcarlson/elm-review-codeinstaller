module MagicLink.Types exposing
    ( EnterEmail_
    , EnterLoginCode_
    , Log
    , LogItem(..)
    , LoginCodeStatus(..)
    , Model
    , Msg(..)
    , PendingLogins
    , SignInState(..)
    , SignInStatus(..)
    , SigninFormState(..)
    )

import AssocList
import Auth.Common
import Dict exposing (Dict)
import EmailAddress exposing (EmailAddress)
import Lamdera
import Route
import Time
import Url
import User


type alias Model =
    { count : Int
    , signInStatus : SignInStatus
    , currentUser : Maybe User.User
    , currentUserData : Maybe User.SignInData
    , signInForm : SigninFormState
    , signInState : SignInState
    , loginErrorMessage : Maybe String
    , realname : String
    , username : String
    , email : String
    , message : String
    , authFlow : Auth.Common.Flow
    , authRedirectBaseUrl : Url.Url
    }


type SignInState
    = SisSignedOut
    | SisSignUp
    | SisSignedIn


type Msg
    = SubmitEmailForSignIn
    | AuthSigninRequested { methodId : Auth.Common.MethodId, email : Maybe String }
    | ReceivedSigninCode String
    | CancelSignIn
    | CancelSignUp
    | OpenSignUp
    | CloseSignUp
    | TypedEmailInSignInForm String
    | SubmitSignUp
    | SignOut
    | InputRealname String
    | InputUsername String
    | InputEmail String
    | SetRoute Route.Route


type SigninFormState
    = EnterEmail EnterEmail_
    | EnterSigninCode EnterLoginCode_


type SignInStatus
    = NotSignedIn
    | ErrorNotRegistered String
    | SuccessfulRegistration String String
    | SigningUp
    | SignedIn


type LoginCodeStatus
    = Checking
    | NotValid


type alias PendingLogins =
    AssocList.Dict
        Lamdera.SessionId
        { loginAttempts : Int
        , emailAddress : EmailAddress
        , creationTime : Time.Posix
        , loginCode : Int
        }


type LogItem
    = LoginsRateLimited User.Id
    | FailedToCreateLoginCode Int


type alias EnterEmail_ =
    { email : String
    , pressedSubmitEmail : Bool
    , rateLimited : Bool
    }


type alias EnterLoginCode_ =
    { sentTo : EmailAddress, loginCode : String, attempts : Dict Int LoginCodeStatus }


type alias Log =
    List ( Time.Posix, LogItem )
