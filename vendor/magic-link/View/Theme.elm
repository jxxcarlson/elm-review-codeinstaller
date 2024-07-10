module View.Theme exposing
    ( contentAttributes
    , css
    )

import Element
import Html exposing (Html)


contentAttributes : List (Element.Attribute msg)
contentAttributes =
    [ Element.width (Element.maximum 800 Element.fill), Element.centerX ]


css : Html msg
css =
    Html.node "style"
        []
        [ Html.text <|
            fontFace 800 "Figtree-ExtraBold" "Open Sans"
                ++ fontFace 700 "Figtree-Bold" "Open Sans"
                ++ fontFace 600 "Figtree-SemiBold" "Open Sans"
                ++ fontFace 500 "Figtree-Medium" "Open Sans"
                ++ fontFace 400 "Figtree-Regular" "Open Sans"
                ++ fontFace 300 "Figtree-Light" "Open Sans"
                ++ fontFace 700 "Fredoka-Bold" "Fredoka"
                ++ fontFace 600 "Fredoka-SemiBold" "Fredoka"
                ++ fontFace 500 "Fredoka-Medium" "Fredoka"
                ++ fontFace 400 "Fredoka-Regular" "Fredoka"
                ++ fontFace 300 "Fredoka-Light" "Fredoka"
                ++ """
/* Spinner */
@-webkit-keyframes spin { 0% { -webkit-transform: rotate(0deg); transform: rotate(0deg); } 100% { -webkit-transform: rotate(360deg); transform: rotate(360deg); } }
@keyframes spin { 0% { -webkit-transform: rotate(0deg); transform: rotate(0deg); } 100% { -webkit-transform: rotate(360deg); transform: rotate(360deg); } }

.spin {
  -webkit-animation: spin 1s infinite linear;
          animation: spin 1s infinite linear;
}
"""
        ]


fontFace : Int -> String -> String -> String
fontFace weight name fontFamilyName =
    """
@font-face {
  font-family: '""" ++ fontFamilyName ++ """';
  font-style: normal;
  font-weight: """ ++ String.fromInt weight ++ """;
  font-stretch: normal;
  font-display: swap;
  src: url(/fonts/""" ++ name ++ """.ttf) format('truetype');
  unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD, U+2192, U+2713;
}"""
