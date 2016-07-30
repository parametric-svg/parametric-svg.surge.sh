module Components.IconButton exposing (view)

import Html exposing (Html, node, text)
import Html.Attributes exposing (attribute, id)

view
  : String
  -> List (Html.Attribute message)
  -> { symbol : String
     , tooltip : String
     }
  -> List (Html message)
view componentNamespace attributes {symbol, tooltip} =
  let
    iconId =
      componentNamespace ++ symbol ++ "-toolbar-icon-button"

  in
    [ node "paper-icon-button"
      ( [ attribute "icon" symbol
        , attribute "alt" tooltip
        , id iconId
        ]
      ++ attributes
      )
      []
    , node "paper-tooltip"
      [ attribute "for" iconId
      ]
      [ text tooltip
      ]
    ]
