module Components.ParametricSvgEditor exposing
  ( Model, Message
  , init, update, subscriptions, view
  , markup
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
import Components.VariablesPanel as VariablesPanel exposing (variables)
import Components.Auth as Auth exposing (token)
import Components.SaveToGist as SaveToGist

{class} =
  withNamespace componentNamespace

styles : List Css.Mixin -> Html.Attribute a
styles =
  Html.Attributes.style << Css.asPairs


-- MODEL

type alias Model =
  { rawMarkup : String
  , variablesPanel : VariablesPanel.Model
  , auth : Auth.Model
  , saveToGist : SaveToGist.Model
  }

init : (Model, Cmd Message)
init =
  let
    (authModel, authCommand) =
      Auth.init

    (saveToGistModel, saveToGistCommand) =
      SaveToGist.init (svgMarkup "")

  in
    { rawMarkup = ""
    , variablesPanel = VariablesPanel.init
    , auth = authModel
    , saveToGist = saveToGistModel
    }
    ! [ Cmd.map AuthMessage authCommand
      , Cmd.map SaveToGistMessage saveToGistCommand
      ]


svgMarkup : String -> String
svgMarkup rawMarkup =
  if contains (regex "^\\s*<svg\\b") rawMarkup
    then rawMarkup
    else "<svg>" ++ rawMarkup ++ "</svg>"


markup : Model -> String
markup model =
  svgMarkup model.rawMarkup


-- UPDATE

type Message
  = UpdateRawMarkup String
  | VariablesPanelMessage VariablesPanel.Message
  | AuthMessage Auth.Message
  | SaveToGistMessage SaveToGist.Message

update : Message -> Model -> (Model, Cmd Message)
update message model =
  case message of
    UpdateRawMarkup rawMarkup ->
      { model
      | rawMarkup = rawMarkup
      , saveToGist =
        SaveToGist.update
          (SaveToGist.UpdateMarkup <| svgMarkup rawMarkup)
          model.saveToGist
        |> fst
      }
      ! []

    VariablesPanelMessage message ->
      let
        variablesPanel =
          VariablesPanel.update message model.variablesPanel

      in
        { model
        | variablesPanel = variablesPanel
        , saveToGist =
          SaveToGist.update
            (SaveToGist.UpdateVariables <| variables variablesPanel)
            model.saveToGist
          |> fst
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

    SaveToGistMessage message ->
      let
        (saveToGistModel, saveToGistCommand) =
          SaveToGist.update message model.saveToGist

      in
        { model
        | saveToGist = saveToGistModel
        }
        ! [ Cmd.map SaveToGistMessage saveToGistCommand
          ]


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Message
subscriptions model =
  Sub.batch
    [ Sub.map AuthMessage <| Auth.subscriptions model.auth
    , Sub.map SaveToGistMessage <| SaveToGist.subscriptions model.saveToGist
    ]


-- VIEW

view : Model -> Html Message
view model =
  let
    display =
      case getSize model.rawMarkup of
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
        ( [ innerHtml (markup model)
          ]
          ++ parametricAttributes
        )
        []

    innerHtml rawMarkup =
      Html.Attributes.property "innerHTML" <| string rawMarkup

    parametricAttributes =
      List.map
        parametricAttribute
        <| variables model.variablesPanel

    parametricAttribute variable =
      attribute variable.name variable.value

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
          List.map (App.map SaveToGistMessage) (SaveToGist.view model.saveToGist)

        Nothing ->
          List.map (App.map AuthMessage) (Auth.view model.auth)

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
          [ onInput UpdateRawMarkup
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
