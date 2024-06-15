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
    [ --Install.TypeVariant.makeRule "Types" "ToBackend" "CounterReset"
      --, Install.TypeVariant.makeRule "Types" "FrontendMsg" "Reset"
      --, Install.ClauseInCase.init "Frontend" "update" "Reset" "( { model | counter = 0 }, sendToBackend CounterReset )"
      --    |> Install.ClauseInCase.withInsertAfter "Increment"
      --    |> Install.ClauseInCase.makeRule
      --, Install.ClauseInCase.init "Backend" "updateFromFrontend" "CounterReset" "( { model | counter = 0 }, broadcast (CounterNewValue 0 clientId) )"
      --    |> Install.ClauseInCase.makeRule
      --, Install.Function.init [ "Frontend" ] "view" viewFunction |> Install.Function.makeRule
      --
      --Install.Import.init "Frontend" "Foo.Bar"
      --  |> Install.Import.withAlias "FB"
      --  |> Install.Import.withExposedValues [ "a", "b", "c" ]
      --  |> Install.Import.makeRule
      --  Install.Import.init "Frontend" "Foo.Bar" |> Install.Import.makeRule
      --, Install.Import.init "Frontend" "Box.Tux" |> Install.Import.makeRule
       Install.Type.makeRule "Frontend" "Magic" [ "Inactive", "Wizard String", "Spell String Int"]
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
