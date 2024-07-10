module Config exposing
    ( contactEmail
    , postmarkApiKey
    , secretKey
    )

import Env
import Postmark


contactEmail : String
contactEmail =
    "foo@bar.com"


postmarkApiKey : Postmark.ApiKey
postmarkApiKey =
    Postmark.apiKey Env.postmarkApiKey


secretKey =
    case Env.mode of
        Env.Development ->
            "devsecret"

        Env.Production ->
            "prodsecret"
