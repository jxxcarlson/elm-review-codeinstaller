module Pages.TermsOfService exposing (view)

import Element exposing (Element)
import Types


view : Types.LoadedModel -> Element Types.FrontendMsg
view _ =
    Element.text "Terms of Service"
