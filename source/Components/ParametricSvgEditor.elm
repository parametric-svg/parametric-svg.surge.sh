module Components.ParametricSvgEditor exposing
  ( Model, Message
  , init, update, view, css
  )

import Html exposing (node, div, text, textarea, span, Html)
import Html.Attributes exposing (attribute, id)
import Html.Events exposing (onInput)
import Html.CssHelpers exposing (withNamespace)
import Html.App as App
import Css.Namespace exposing (namespace)
import Css exposing
  ( Stylesheet
  , stylesheet, (.), selector, children

  , height, width, display, displayFlex, position, backgroundColor, flexGrow
  , minHeight, maxHeight, paddingTop, top, property

  , pct, block, hex, relative, px, int, absolute, zero
  )
import Json.Encode exposing (string)
import Regex exposing (regex, contains)
import String
import Maybe exposing (andThen)

import Components.VariablesPanel as VariablesPanel
import Components.Auth as Auth
import Components.IconButton as IconButton

{class} =
  withNamespace componentNamespace

styles : List Css.Mixin -> Html.Attribute a
styles =
  Html.Attributes.style << Css.asPairs


-- MODEL

type alias Model =
  { source : String
  , liveSource : String
  , variablesPanel : VariablesPanel.Model
  , auth : Auth.Model
  }

init : Model
init =
  { source = ""
  , liveSource = ""
  , variablesPanel = VariablesPanel.init
  , auth = Auth.init
  }


-- UPDATE

type Message
  = UpdateSource String
  | InjectSourceIntoDrawing
  | VariablesPanelMessage VariablesPanel.Message
  | AuthMessage Auth.Message
  | Noop ()

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
      { model
      | variablesPanel = VariablesPanel.update message model.variablesPanel
      }

    AuthMessage message ->
      { model
      | auth = Auth.update message model.auth
      }

    Noop _ ->
      model


-- VIEW

view : Model -> Html Message
view model =
  let
    display =
      case getSize model.source of
        Just (drawingWidth, drawingHeight) ->
          div
            [ class [Display]
            , styles
              [ maxHeight (px drawingHeight)
              ]
            ]
            [ div
              [ class [DisplaySizer]
              , styles
                [ paddingTop (pct <| drawingHeight / drawingWidth * 100)
                ]
              ] []
            , parametricSvg
            ]

        Nothing ->
          div
            [ class [Display, Display_ImplicitSize]
            ]
            [ parametricSvg
            ]

    parametricSvg =
      node "parametric-svg"
        ( [ innerHtml svgSource
          ]
          ++ parametricAttributes
        )
        []

    innerHtml source =
      Html.Attributes.property "innerHTML" <| string source

    svgSource =
      if contains (regex "^\\s*<svg\\b") model.source
        then model.source
        else "<svg>" ++ model.source ++ "</svg>"

    parametricAttributes =
      List.map
        parametricAttribute
        <| VariablesPanel.getVariables model.variablesPanel

    parametricAttribute variable =
      attribute variable.name variable.rawValue

    title titleLine =
      [ div
        [ Html.Attributes.class "title"
        ]
        [ text "parametric-svg"
        ]
      ]

    toolbarButtons =
      case Auth.token model.auth of
        Just _ ->
          ( iconButton "cloud-download" "Open gist"
          ++ iconButton "cloud-upload" "Save as gist"
          )

        Nothing ->
          List.map (App.map AuthMessage) <| Auth.view model.auth

    iconButton =
      IconButton.view Noop componentNamespace

  in
    node "paper-header-panel"
      [ class [Root]
      , attribute "mode" "waterfall"
      ]
      [ node "paper-toolbar"
        [ class [Toolbar]
        ]
        <| title "parametric-svg"
        ++ toolbarButtons

      , App.map VariablesPanelMessage (VariablesPanel.view model.variablesPanel)

      , display

      , node "codemirror-editor"
        [ class [Editor]
        ]
        [ textarea
          [ onInput UpdateSource
          ] []
        ]
      ]

type IconButtonState
  = Active
  | Disabled

type alias Size =
  Maybe (Float, Float)

getSize : String -> Size
getSize source =
  let
    dimensionRegex dimension =
      regex
        <| "^\\s*<svg\\b[^>]*\\b"
        ++ dimension
        ++ "=\"(\\d+|\\d*(?:\\.\\d+)?)\""

    dimensionFloat : String -> Maybe Float
    dimensionFloat dimension =
      ( List.head <| Regex.find (Regex.AtMost 1)
          (dimensionRegex dimension)
          source
      )

      `andThen`
      \match -> List.head match.submatches

      `andThen`
      \submatch ->
        case submatch of
          Just value ->
            Result.toMaybe <| String.toFloat value

          Nothing ->
            Nothing

  in
    case (dimensionFloat "width", dimensionFloat "height") of
      (Just width, Just height) ->
        Just (width, height)

      _ ->
        Nothing


-- STYLES

type Classes
  = Root
  | Display | Display_ImplicitSize
  | DisplaySizer
  | Editor
  | Toolbar

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
      [ backgroundColor toolbarBackgroundColor
      ]

    , (.) Toolbar
      [ backgroundColor toolbarBackgroundColor
      , property "--paper-toolbar-title" <| "{ "
        ++ "margin-left: 0; "
        ++ "line-height: 1.5; "
        ++ "}"
      ]

    , (.) Display
      [ position relative
      , flexGrow (int 1)
      , backgroundColor white
      ]
    , (.) Display [children [selector "parametric-svg > svg"
      [ position absolute
      , top zero
      , width (pct 100)
      , height (pct 100)
      ]]]
    , (.) Display_ImplicitSize
      [ minHeight (pct 60)
      ]

    , (.) DisplaySizer
      [ width (pct 100)
      ]

    , (.) Editor
      [ display block
      , flexGrow (int 1)
      ]
    ]

componentNamespace : String
componentNamespace = "a3e78af-ParametricSvgEditor-"
