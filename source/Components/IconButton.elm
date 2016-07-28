module Components.IconButton exposing (view)

import Html exposing (Html, node, text)
import Html.App as App
import Html.Attributes exposing (attribute, id)

view : (a -> message) -> String -> String -> String -> List (Html message)
view message componentNamespace symbol tooltip =
  let
    iconId =
      componentNamespace ++ symbol ++ "-toolbar-icon-button"

  in
    List.map (App.map message) <|
      [ node "paper-icon-button"
        [ attribute "icon" symbol
        , attribute "alt" tooltip
        , id iconId
        ]
        []
      , node "paper-tooltip"
        [ attribute "for" iconId
        ]
        [ text tooltip
        ]
      ]
