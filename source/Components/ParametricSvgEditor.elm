module Components.ParametricSvgEditor exposing
  ( Model, Message
  , init, update, subscriptions, view
  )

import Html exposing (node, div, text, textarea, span, Html)
import Html.Attributes exposing (attribute, id)
import Html.Events exposing (onInput)
import Html.CssHelpers exposing (withNamespace)
import Html.App as App
import Css exposing (maxHeight, paddingTop, px, pct)
import Json.Encode exposing (string)
import Regex exposing (regex, contains)
import String
import Maybe exposing (andThen)

import Styles.ParametricSvgEditor exposing
  ( Classes(Root, Display, Display_ImplicitSize, DisplaySizer, Editor, Toolbar)
  , componentNamespace
  )
import Components.IconButton as IconButton
import Components.VariablesPanel as VariablesPanel exposing (variables)
import Components.Auth as Auth exposing (token)
import Components.IconButton as IconButton

{class} =
  withNamespace componentNamespace

styles : List Css.Mixin -> Html.Attribute a
styles =
  Html.Attributes.style << Css.asPairs


-- MODEL

type alias Model =
  { source : String
  , variablesPanel : VariablesPanel.Model
  , auth : Auth.Model
  }

init : (Model, Cmd Message)
init =
  let
    (authModel, authCommand) =
      Auth.init

  in
    { source = ""
    , variablesPanel = VariablesPanel.init
    , auth = authModel
    }
    ! [ Cmd.map AuthMessage authCommand
      ]


-- UPDATE

type Message
  = UpdateSource String
  | VariablesPanelMessage VariablesPanel.Message
  | AuthMessage Auth.Message
  | Noop ()

update : Message -> Model -> (Model, Cmd Message)
update message model =
  case message of
    UpdateSource source ->
      { model
      | source = source
      }
      ! []

    VariablesPanelMessage message ->
      { model
      | variablesPanel = VariablesPanel.update message model.variablesPanel
      }
      ! []

    AuthMessage message ->
      let
        (authModel, authCommand) =
          Auth.update message model.auth

      in
        { model
        | auth = authModel
        }
        ! [ Cmd.map AuthMessage authCommand
          ]

    Noop _ ->
      model ! []


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Message
subscriptions model =
  Sub.map AuthMessage <| Auth.subscriptions model.auth


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
        <| variables model.variablesPanel

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
      case token model.auth of
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
