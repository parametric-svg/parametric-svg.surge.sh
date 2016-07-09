module ParametricSvgEditor exposing
  ( Model, Message
  , init, update, view, css
  )

import Svg exposing (svg)
import Html exposing (node, div, text, textarea, Html)
import Html.Attributes exposing (attribute, property)
import Html.Events exposing (onInput)
import Html.CssHelpers exposing (withNamespace)
import Css.Namespace exposing (namespace)
import Css exposing
  ( Stylesheet
  , stylesheet, (.), selector, children
  , height, width, display
  , pct, block
  )
import Json.Encode exposing (string)

{class} =
  withNamespace componentNamespace


-- MODEL

type alias Model =
  { source : String
  , liveSource : String
  }

init : Model
init =
  { source = ""
  , liveSource = ""
  }


-- UPDATE

type Message
  = UpdateSource String
  | InjectSourceIntoDrawing

update : Message -> Model -> Model
update message model =
  case message of
    UpdateSource source ->
      { model
      | source = source
      }

    InjectSourceIntoDrawing ->
      { model
      | liveSource = model.source
      }


-- VIEW

view : Model -> Html Message
view model =
  let
    innerHtml source =
      property "innerHTML" <| string source

  in
    node "paper-header-panel"
      [ class [Root]
      , attribute "mode" "waterfall"
      ]
      [ node "paper-toolbar" []
        [ div [] [text "parametric-svg"]
        ]
      , div []
        [ node "parametric-svg"
          [ class [Display]
          ]
          [ svg [innerHtml model.source] []
          ]
        ]
      , node "codemirror-editor"
        []
        [ textarea [onInput UpdateSource] []
        ]
      ]


-- STYLES

type Classes = Root | Display

css : Stylesheet
css = (stylesheet << namespace componentNamespace)
  [ (.) Root
    [ height <| pct 100
    ]

  , (.) Display [children [selector "svg"
    [ display block
    , width <| pct 100
    ]]]
  ]

componentNamespace : String
componentNamespace = "a3e78af-"
