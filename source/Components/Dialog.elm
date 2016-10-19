module Components.Dialog exposing
  ( onCloseOverlay
  , dialog
  )

import Html exposing (Html, Attribute, node)
import Html.Attributes exposing (attribute)
import Html.Events exposing (on)
import Json.Decode as Decode




-- EVENTS

onCloseOverlay : message -> Attribute message
onCloseOverlay command =
  on "iron-overlay-closed" (Decode.succeed command)




-- VIEW

dialog : List (Attribute message) -> List (Html message) -> Html message
dialog attributes children =
  node "submit-on-enter" []
  [ node "paper-dialog"
    ( [ attribute "opened" ""
      ]
    ++ attributes
    )
    children
  ]
