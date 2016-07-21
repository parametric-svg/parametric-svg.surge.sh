module ParametricSvgEditor exposing
  ( Model, Message
  , init, update, view, css
  )

import Html exposing (node, div, text, textarea, Html)
import Html.Attributes exposing (attribute, property)
import Html.Events exposing (onInput)
import Html.CssHelpers exposing (withNamespace)
import Html.App as App
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
  | VariablesPanelMessage VariablesPanel.Message

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

    VariablesPanelMessage message ->
      model


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
        <| VariablesPanel.getVariables model.variablesPanel

    parametricAttribute variable =
      attribute variable.name variable.rawValue

  in
    node "paper-header-panel"
      [ class [Root]
      , attribute "mode" "waterfall"
      ]
      [ node "paper-toolbar"
        [ class [Toolbar]
        ]
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
      , App.map VariablesPanelMessage <| VariablesPanel.view model.variablesPanel
      , node "codemirror-editor"
        [ class [Editor]
        ]
        [ textarea
          [ onInput UpdateSource
          ] []
        ]
      ]


-- STYLES

type Classes = Root | Display | Editor | Toolbar

css : Stylesheet
css = (stylesheet << namespace componentNamespace) <|
  let
    toolbarBackgroundColor =
      hex "8BC34A"
      -- Light Green 500

    codemirrorMaterialBackgroundColor =
      hex "263238"
      -- Blue Grey 900

    white =
      hex "FFFFFF"

  in
    [ (.) Root
      [ height <| pct 100
      , displayFlex
      , backgroundColor codemirrorMaterialBackgroundColor
      ]

    , selector "html"
      [ backgroundColor codemirrorMaterialBackgroundColor
      ]

    , (.) Toolbar
      [ backgroundColor toolbarBackgroundColor
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
componentNamespace = "a3e78af-ParametricSvgEditor-"
