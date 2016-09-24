port module Components.ParametricSvgEditor exposing
  ( Model, Message
  , init, update, subscriptions, view
  , markup
  )

import Html exposing (node, div, text, textarea, span, Html)
import Html.Attributes exposing (attribute, id)
import Html.Events exposing (onInput, on)
import Html.CssHelpers exposing (withNamespace)
import Html.App as App
import Css exposing (maxHeight, paddingTop, px, pct)
import Json.Encode exposing (string)
import Json.Decode as Decode exposing ((:=), Decoder)
import Regex exposing (regex, HowMany(AtMost))
import String
import Maybe exposing (andThen)

import UniversalTypes exposing (ToastContent, Variable)
import Styles.ParametricSvgEditor exposing
  ( Classes
    ( Root
    , Display, Display_ImplicitSize
    , DisplaySizer
    , Editor
    , Toolbar
    )
  , componentNamespace
  )
import Components.VariablesPanel as VariablesPanel exposing (variables)
import Components.Auth as Auth exposing (token)
import Components.SaveToGist as SaveToGist
import Components.Toast as Toast

{class} =
  withNamespace componentNamespace

styles : List Css.Mixin -> Html.Attribute a
styles =
  Html.Attributes.style << Css.asPairs




-- MODEL

type alias Model =
  { rawMarkup : String
  , canvasSize : Maybe CanvasSize
  , variablesPanel : VariablesPanel.Model
  , auth : Auth.Model
  , saveToGist : SaveToGist.Model
  , toasts : List ToastContent
  }

type alias CanvasSize =
  { width : Int
  , height : Int
  }

init : (Model, Cmd Message)
init =
  let
    (authModel, authCommand) =
      Auth.init

    (saveToGistModel, saveToGistCommand) =
      SaveToGist.init (svgMarkup "" Nothing)

  in
    { rawMarkup = ""
    , canvasSize = Nothing
    , variablesPanel = VariablesPanel.init
    , auth = authModel
    , saveToGist = saveToGistModel
    , toasts = []
    }
    ! [ Cmd.map AuthMessage authCommand
      , Cmd.map SaveToGistMessage saveToGistCommand
      ]


svgMarkup : String -> Maybe CanvasSize -> String
svgMarkup rawMarkup canvasSize =
  let
    markupWithoutSize =
      if Regex.contains (regex "^\\s*<svg\\b") rawMarkup
        then rawMarkup
        else "<svg>" ++ rawMarkup ++ "</svg>"

  in
    case canvasSize of
      Just size ->
        Regex.replace
          (AtMost 1)
          (regex "(^\\s*<svg\\b.*?)(>)")
          (\{match, submatches} ->
            case submatches of
              [Just beginning, Just end] ->
                beginning
                ++ " viewBox=\""
                  ++ "0 "
                  ++ "0 "
                  ++ toString size.width ++ " "
                  ++ toString size.height ++ "\""
                ++ " width=\"" ++ toString size.width ++ "\""
                ++ " height=\"" ++ toString size.height ++ "\""
                ++ end

              _ ->
                match
          )
          markupWithoutSize
          -- We rely on the fact that the browser ignores repeating attributes
          -- and only takes its first occurence in an element into account.

      Nothing ->
        markupWithoutSize


markup : Model -> String
markup model =
  svgMarkup model.rawMarkup model.canvasSize




-- UPDATE

port requestFileContents
  : {drawingId : String, variables : List Variable}
  -> Cmd message

type Message
  = UpdateRawMarkup String
  | RequestFileContents
  | ReceiveFileContents FileContentsSerializationOutput
  | ReceiveCanvasSize CanvasSize
  | VariablesPanelMessage VariablesPanel.Message
  | AuthMessage Auth.Message
  | SaveToGistMessage SaveToGist.Message

type alias FileContentsSerializationOutput =
  { payload : Maybe String
  , error : Maybe ToastContent
  }

update : Message -> Model -> (Model, Cmd Message)
update message model =
  case message of
    UpdateRawMarkup rawMarkup ->
      let
        modelWithMarkup =
          { model
          | rawMarkup = rawMarkup
          }

        (saveToGist, _, _) =
          SaveToGist.update
            (SaveToGist.UpdateMarkup <| markup modelWithMarkup)
            model.saveToGist

      in
        { modelWithMarkup
        | saveToGist = saveToGist
        }
        ! []

    RequestFileContents ->
      model
      ! [ requestFileContents
          { drawingId = drawingId
          , variables = variables model.variablesPanel
          }
        ]

    ReceiveFileContents {payload, error} ->
      case (payload, error) of
        (_, Just failureToast) ->
          { model
          | toasts = failureToast :: model.toasts
          }
          ! []

        (Just fileContents, Nothing) ->
          update
            (SaveToGistMessage <| SaveToGist.AcceptFileContents fileContents)
            model

        (Nothing, Nothing) ->
          model ! []

    ReceiveCanvasSize canvasSize ->
      let
        modelWithCanvas =
          { model
          | canvasSize = Just canvasSize
          }

        (saveToGist, _, _) =
          SaveToGist.update
            (SaveToGist.UpdateMarkup <| markup modelWithCanvas)
            model.saveToGist

      in
        { modelWithCanvas
        | saveToGist = saveToGist
        }
        ! []

    VariablesPanelMessage message ->
      let
        variablesPanel =
          VariablesPanel.update message model.variablesPanel

        (saveToGist, _, _) =
          SaveToGist.update
            (SaveToGist.UpdateVariables (variables variablesPanel))
            model.saveToGist

      in
        { model
        | variablesPanel = variablesPanel
        , saveToGist = saveToGist
        }
        ! []

    AuthMessage message ->
      let
        (authModel, authCommand) =
          Auth.update message model.auth

        updatedModel =
          case message of
            Auth.ReceiveToken token ->
              modelWithToken token

            Auth.LoadToken (Just token) ->
              modelWithToken token

            _ ->
              { model
              | auth = authModel
              }

        modelWithToken token =
          let
            (saveToGist, _, _) =
              SaveToGist.update
                (SaveToGist.AcceptToken token)
                model.saveToGist

          in
            { model
            | auth = authModel
            , saveToGist = saveToGist
            }

      in
        updatedModel
        ! [ Cmd.map AuthMessage authCommand
          ]

    SaveToGistMessage message ->
      let
        (saveToGistModel, saveToGistCommand, messageToParent) =
          SaveToGist.update message model.saveToGist

        (parentModel, parentCommand) =
          case messageToParent of
            SaveToGist.FileContentsPlease ->
              update RequestFileContents model

            SaveToGist.Nada ->
              model ! []

      in
        { parentModel
        | saveToGist = saveToGistModel
        }
        ! [ Cmd.map SaveToGistMessage saveToGistCommand
          , parentCommand
          ]


drawingId : String
drawingId =
  componentNamespace ++ "drawing"




-- SUBSCRIPTIONS

port fileContents
  : (FileContentsSerializationOutput -> message)
  -> Sub message

subscriptions : Model -> Sub Message
subscriptions model =
  Sub.batch
    [ Sub.map AuthMessage <| Auth.subscriptions model.auth
    , fileContents ReceiveFileContents
    ]




-- VIEW

view : Model -> Html Message
view model =
  let
    display =
      case size of
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
          node "dimensions-watch"
            [ class [Display, Display_ImplicitSize]
            , id drawingId
            , onReceiveSize ReceiveCanvasSize
            ]
            [ parametricSvg
            ]

    size =
      case (dimensionFloat "width", dimensionFloat "height") of
        (Just width, Just height) ->
          Just (width, height)

        _ ->
          Nothing

    dimensionFloat : String -> Maybe Float
    dimensionFloat dimension =
      ( List.head <| Regex.find (Regex.AtMost 1)
        (dimensionRegex dimension)
        model.rawMarkup
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

    dimensionRegex dimension =
      regex
        <| "^\\s*<svg\\b[^>]*\\b"
        ++ dimension
        ++ "=\"(\\d+|\\d*(?:\\.\\d+)?)\""

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
      <| [ node "paper-toolbar"
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
      ++ Toast.toasts model


type IconButtonState
  = Active
  | Disabled

onReceiveSize : (CanvasSize -> Message) -> Html.Attribute Message
onReceiveSize action =
  on "size" <| Decode.map action decodeSize

decodeSize : Decoder CanvasSize
decodeSize =
  Decode.at ["detail"]
  <| Decode.object2 CanvasSize
    ("width" := Decode.map round Decode.float)
    ("height" := Decode.map round Decode.float)
