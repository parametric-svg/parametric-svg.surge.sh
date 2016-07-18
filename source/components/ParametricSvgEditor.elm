module ParametricSvgEditor exposing
  ( Model, Message
  , init, update, view, css
  )

import Html exposing (node, div, text, textarea, Html)
import Html.Attributes exposing (attribute, property)
import Html.Events exposing (onInput)
import Html.CssHelpers exposing (withNamespace)
import Css.Namespace exposing (namespace)
import Css exposing
  ( Stylesheet
  , stylesheet, (.), selector, children

  , height, width, display, displayFlex, position, backgroundColor, flexGrow
  , minHeight

  , pct, block, hex, relative, px, int, absolute
  , src
  )
import Json.Encode exposing (string)
import Regex exposing (regex, contains)

import VariablesPanel

{class} =
  withNamespace componentNamespace


-- MODEL

type alias Model =
  { source : String
  , liveSource : String
  , variablesPanel : VariablesPanel.Model
  }

init : Model
init =
  { source = ""
  , liveSource = ""
  , variablesPanel = VariablesPanel.init
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

    svgSource =
      if contains (regex "^<svg") model.source
        then model.source
        else "<svg>" ++ model.source ++ "</svg>"

    parametricAttributes =
      List.map
        parametricAttribute
        model.variablesPanel.variables

    parametricAttribute variable =
      attribute variable.name variable.rawValue

  in
    node "paper-header-panel"
      [ class [Root]
      , attribute "mode" "waterfall"
      ]
      [ node "paper-toolbar" []
        [ div [] [text "parametric-svg"]
        ]
      , div
        [ class [Display]
        ]
        [ node "parametric-svg"
          ( [ innerHtml svgSource
            ]
          ++ parametricAttributes
          )
          []
        ]
      , node "codemirror-editor"
        [ class [Editor]
        ]
        [ textarea
          [ onInput UpdateSource
          ] []
        ]
      ]


-- STYLES

type Classes = Root | Display | Editor

css : Stylesheet
css = (stylesheet << namespace componentNamespace) <|
  let
    paperToolbarBackgroundColor =
      hex "3f51b5"
    codemirrorMaterialBackgroundColor =
      hex "263238"
    white =
      hex "ffffff"
  in
    [ (.) Root
      [ height <| pct 100
      , displayFlex
      , backgroundColor codemirrorMaterialBackgroundColor
      ]

    , (.) Display
      [ position relative
      , flexGrow (int 1)
      , minHeight (pct 60)
      , backgroundColor white
      ]
    , (.) Display [children [selector "parametric-svg > svg"
      [ position absolute
      , width (pct 100)
      , height (pct 100)
      ]]]

    , (.) Editor
      [ display block
      , flexGrow (int 1)
      ]
    ]

componentNamespace : String
componentNamespace = "a3e78af-"
