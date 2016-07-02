module ParametricSvgEditor exposing
  ( Model, Message
  , init, update, view
  )

import Html exposing (node, div, text, Html)
import Html.Attributes exposing (attribute)
import Html.CssHelpers exposing (withNamespace)
import Css.Namespace exposing (namespace)
import Css exposing
  ( Stylesheet
  , stylesheet, (.)
  , height
  , pct
  )

{class} =
  withNamespace componentNamespace


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
    , class [Root]
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


-- STYLES

type Classes
  = Root

css : Stylesheet
css = (stylesheet << namespace componentNamespace)
  [ (.) Root
    [ height (pct 100)
    ]
  ]

componentNamespace : String
componentNamespace = "3de78af-"
