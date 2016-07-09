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
  , stylesheet, (.), selector, children, after
  , height, width, display, position, backgroundColor, top
  , pct, block, hex, relative, absolute, zero, px
  , src
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
        [ class [Editor]
        ]
        [ textarea [onInput UpdateSource] []
        ]
      ]


-- STYLES

type Classes = Root | Display | Editor

css : Stylesheet
css = (stylesheet << namespace componentNamespace)
  <| let
    paperToolbarBackgroundColor =
      hex "3f51b5"
    codemirrorMaterialBackgroundColor =
      hex "263238"
  in
    [ (.) Root
      [ height <| pct 100
      ]

    , (.) Display [children [selector "svg"
      [ display block
      , width <| pct 100
      ]]]

    , (.) Editor
      [ position relative
      , display block
      ]
    , (.) Editor [after
      [ Css.property "content" "''"
      , position absolute
      , Css.property "z-index" "-1"
      , display block
      , height (px 99999)
      , backgroundColor codemirrorMaterialBackgroundColor
      ]]
    ]

componentNamespace : String
componentNamespace = "a3e78af-"
