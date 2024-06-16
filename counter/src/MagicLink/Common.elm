module MagicLink.Common exposing (sendMessage)

import Auth.Common
import Lamdera
import Types



-- sendMessage : ClientId -> String -> Cmd msg


sendMessage clientId message =
    Lamdera.sendToFrontend clientId
        ((Types.AuthToFrontend << Auth.Common.ReceivedMessage) (Ok message))
