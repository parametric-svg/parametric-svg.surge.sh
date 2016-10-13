module Components.ParametricSvgEditor exposing
  ( Model, Message(ChangeLocation), Location
  , init, update, subscriptions, view
  , urlToLocation
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
import Http exposing
  ( Error(Timeout, BadResponse, UnexpectedPayload, NetworkError)
  )

import Types exposing
  ( ToastContent, Variable, Context, FileSnapshot, GistData
  , GistState(NotConnected)
  )
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
import Components.Auth as Auth
import Components.SaveToGist as SaveToGist
import Components.OpenGist as OpenGist
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
  , openGist : OpenGist.Model
  , toasts : List ToastContent
  , githubAuthToken : Maybe String
  , gistState : GistState
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
      SaveToGist.init

    (openGistModel, openGistCommand) =
      OpenGist.init

  in
    { rawMarkup = ""
    , canvasSize = Nothing
    , variablesPanel = VariablesPanel.init
    , auth = authModel
    , saveToGist = saveToGistModel
    , openGist = openGistModel
    , toasts = []
    , githubAuthToken = Nothing
    , gistState = NotConnected
    }
    ! [ Cmd.map AuthMessage authCommand
      , Cmd.map SaveToGistMessage saveToGistCommand
      , Cmd.map OpenGistMessage openGistCommand
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


context : Model -> Context
context model =
  { githubAuthToken = model.githubAuthToken
  , drawingId = drawingId
  , variables = variables model.variablesPanel
  , markup = markup model
  , gistState = model.gistState
  }




-- NAVIGATION

type Location
  = BlankCanvas
  | Gist GistData
  | Lost


urlToLocation : String -> Location
urlToLocation url =
  let
    pattern =
      regex
        -- /
        ( "^/"
        ++ ( "(?:"
          -- …gist-<gist id>
          ++ "gist-([^/]+)"
          ++ ( "(?:"
            -- …/<gist basename>
            ++ "/([^/]+)"
            ++ ")?"
            )
          ++ ")?"
          )
        ++ "$"
        )

    matches =
      Regex.find (AtMost 1) pattern url

  in case matches of
    [match] ->
      case match.submatches of
        [Nothing, Nothing] ->
          BlankCanvas

        [Just id, Just basename] ->
          Gist {id = id, basename = basename}

        _ ->
          Lost

    _ ->
      Lost


locationToUrl : Location -> String
locationToUrl location =
  case location of
    BlankCanvas ->
      "/"

    Gist {id, basename} ->
      "/gist-" ++ id ++ "/" ++ basename

    Lost ->
      Debug.crash "No such URL"




-- UPDATE

type Message
  = UpdateRawMarkup String
  | ReceiveCanvasSize CanvasSize
  | ChangeLocation Location
  | VariablesPanelMessage VariablesPanel.Message
  | AuthMessage Auth.Message
  | SaveToGistMessage SaveToGist.Message
  | OpenGistMessage OpenGist.Message

update : Message -> Model -> (Model, Cmd Message)
update message model =
  case message of
    UpdateRawMarkup rawMarkup ->
      { model
      | rawMarkup = rawMarkup
      }
      ! []

    ReceiveCanvasSize canvasSize ->
      { model
      | canvasSize = Just canvasSize
      }
      ! []

    VariablesPanelMessage message ->
      { model
      | variablesPanel = VariablesPanel.update message model.variablesPanel
      }
      ! []

    AuthMessage message ->
      let
        (authModel, authCommand, messageToParent) =
          Auth.update message model.auth

        newModel =
          case messageToParent of
            Auth.Nada ->
              model

            Auth.UpdateToken maybeToken ->
              { model
              | githubAuthToken = maybeToken
              }

      in
        newModel
        ! [ Cmd.map AuthMessage authCommand
          ]

    SaveToGistMessage message ->
      let
        (saveToGistModel, saveToGistCommand, messageToParent) =
          SaveToGist.update message model.saveToGist

        newModel =
          case messageToParent of
            SaveToGist.Nada ->
              model

            SaveToGist.SetGistState gistState ->
              { model
              | gistState = gistState
              }

            SaveToGist.HandleHttpError (Timeout) ->
              failure
                <| "Uh-oh! The github API request timed out. Trying again "
                ++ "should help. Not kidding!"
            SaveToGist.HandleHttpError (NetworkError) ->
              failure
                <| "Aw, shucks! The network failed us this time. Try again "
                ++ "in a few moments."
            SaveToGist.HandleHttpError (UnexpectedPayload message) ->
              failure
                <| "Huh? We don’t understand the response from the github API. "
                ++ "Here’s what our decoder says: “" ++ message ++ "”."
            SaveToGist.HandleHttpError (BadResponse number message) ->
              failure
                <| "Yikes! The github API responded "
                ++ "with a " ++ toString number ++ " error. "
                ++ "Here’s what they say: “" ++ message ++ "”."

        failure message =
          { model
          | gistState = NotConnected
          , toasts = Toast.getHelp message :: model.toasts
          }

      in
        { newModel
        | saveToGist = saveToGistModel
        }
        ! [ Cmd.map SaveToGistMessage saveToGistCommand
          ]

    OpenGistMessage message ->
      let
        (openGistModel, openGistCommand, messageToParent) =
          OpenGist.update message model.openGist

        newModel =
          case messageToParent of
            OpenGist.Nada ->
              model

            OpenGist.SetGistState gistState ->
              { model
              | gistState = gistState
              }

      in
        { newModel
        | openGist = openGistModel
        }
        ! [ Cmd.map OpenGistMessage openGistCommand
          ]

    ChangeLocation location ->
      case location of
        BlankCanvas ->
          { model
          | gistState = NotConnected
          }
          ! []

        Gist gistData ->
          update (OpenGistMessage <| OpenGist.SetGistData gistData) model

        Lost ->
          { model
          | toasts = Toast.takeMeHome
            ( "Errr, we can’t find anything at that URL."
            ) :: model.toasts
          }
          ! []



drawingId : String
drawingId =
  componentNamespace ++ "drawing"




-- SUBSCRIPTIONS

subscriptions : Model -> Sub Message
subscriptions model =
  Sub.batch
    [ Sub.map AuthMessage
      <| Auth.subscriptions model.auth

    , Sub.map SaveToGistMessage
      <| SaveToGist.subscriptions (context model) model.saveToGist

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

    openGistButton =
      OpenGist.view (context model) model.openGist
      |> List.map (App.map OpenGistMessage)

    saveToGistOrAuthButton =
      case model.githubAuthToken of
        Just _ ->
          SaveToGist.view (context model) model.saveToGist
          |> List.map (App.map SaveToGistMessage)

        Nothing ->
          Auth.view (context model) model.auth
          |> List.map (App.map AuthMessage)

  in
    node "paper-header-panel"
      [ class [Root]
      , attribute "mode" "waterfall"
      ]
      <| [ node "paper-toolbar"
          [ class [Toolbar]
          ]
          <| title "parametric-svg"
          ++ openGistButton
          ++ saveToGistOrAuthButton

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
