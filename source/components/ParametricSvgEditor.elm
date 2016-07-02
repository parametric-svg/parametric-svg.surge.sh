module ParametricSvgEditor exposing
  ( Model, Message
  , init, update, view
  )

import Html exposing (node, div, text, Html)
import Html.Attributes exposing (attribute)


-- MODEL

type alias Model =
  ()

init : Model
init =
  ()


-- UPDATE

type alias Message =
  ()

update : Message -> Model -> Model
update _ _ =
  ()


-- VIEW

view : Model -> Html Message
view _ =
  node "paper-header-panel"
    [ attribute "mode" "waterfall"
    ]
    [ node "paper-toolbar" []
      [ div []
        [ text "parametric-svg"
        ]
      ]
    , div []
      [ text "(content goes here)"
      ]
    ]
