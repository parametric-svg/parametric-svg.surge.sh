module Components.ParametricSvgEditor exposing
  ( Model, Message(ChangeLocation), Location
  , init, update, subscriptions, view
  , urlToLocation
  , markup
  )

import Html exposing (node, div, text, textarea, span, Html)
import Html.Attributes exposing (attribute, id, value)
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
  , GistState(NotConnected, Synced)
  )
import Components.ParametricSvgEditor.Styles exposing
  ( Classes
    ( Root
    , Display, Display_ImplicitSize
    , DisplaySizer
    , Editor
    , Toolbar
    , ToolbarButton
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
    markupWithSvgTags =
      if Regex.contains (regex svgTagFromBeginning) rawMarkup
        then rawMarkup
        else "<svg>" ++ rawMarkup ++ "</svg>"

    svgTagFromBeginning =
      "^\\s*<svg\\b[^>]*"

    hasSize =
      containsAttribute "viewBox"
      && containsAttribute "width"
      && containsAttribute "height"

    containsAttribute attribute =
      Regex.contains (attributeRegex attribute) rawMarkup

    attributeRegex attribute =
      regex
        ( "(" ++ svgTagFromBeginning ++ ")"
        ++ "\\s*" ++ attribute ++ "=\"[^>\"]*\""
        )

    markupWithoutSize =
      markupWithSvgTags
      |> removeAttribute "viewBox"
      |> removeAttribute "width"
      |> removeAttribute "height"

    removeAttribute attribute =
      Regex.replace (AtMost 1) (attributeRegex attribute) leaveFirstGroup

    leaveFirstGroup {submatches} =
      Maybe.withDefault ""
        ( List.head submatches
          `andThen`
          identity
        )

  in
    case (hasSize, canvasSize) of
      (True, _) ->
        rawMarkup

      (False, Just size) ->
        Regex.replace
          (AtMost 1)
          (regex <| "(" ++ svgTagFromBeginning ++ ")(>)")
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

      (False, Nothing) ->
        markupWithSvgTags


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

update
  : (String -> Cmd Message)
  -> Message
  -> Model
  -> (Model, Cmd Message)
update modifyUrl message model =
  let
    httpFailure intermediateModel error =
      case error of
        Timeout ->
          failure intermediateModel
            <| "Uh-oh! The github API request timed out. Trying again "
            ++ "should help. Not kidding!"

        NetworkError ->
          failure intermediateModel
            <| "Aw, shucks! The network failed us this time. Try again "
            ++ "in a few moments."

        UnexpectedPayload message ->
          failure intermediateModel
            <| "Huh? We don’t understand the response from the github API. "
            ++ "Here’s what our decoder says: “" ++ message ++ "”."

        BadResponse number message ->
          failure intermediateModel
            <| "Yikes! The github API responded "
            ++ "with a " ++ toString number ++ " error. "
            ++ "Here’s what they say: “" ++ message ++ "”."

    failure intermediateModel message =
      { model
      | gistState = NotConnected
      , toasts = Toast.getHelp message :: model.toasts
      }

  in
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
            { model
            | saveToGist = saveToGistModel
            }

          setGistState gistState =
            { newModel
            | gistState = gistState
            }
            ! ( [ Cmd.map SaveToGistMessage saveToGistCommand
                ]
              ++ gistStateNavigationCommands gistState
              )

          gistStateNavigationCommands gistState =
            case gistState of
              Synced gistData _ ->
                [ modifyUrl (locationToUrl <| Gist gistData)
                ]

              _ ->
                []


        in
          case messageToParent of
            SaveToGist.Nada ->
              newModel
              ! [ Cmd.map SaveToGistMessage saveToGistCommand
                ]

            SaveToGist.SetGistState gistState ->
              setGistState gistState

            SaveToGist.SetGistStateAndMarkup gistState markup ->
              let
                (newerModel, commands) =
                  setGistState gistState

              in
                ( { newerModel
                  | rawMarkup = markup
                  }
                , commands
                )

            SaveToGist.SetMarkup markup ->
              { newModel
              | rawMarkup = markup
              }
              ! [ Cmd.map SaveToGistMessage saveToGistCommand
                ]

            SaveToGist.HandleHttpError error ->
              httpFailure newModel error
              ! [ Cmd.map SaveToGistMessage saveToGistCommand
                ]


      OpenGistMessage message ->
        let
          (openGistModel, openGistCommand, messageToParent) =
            OpenGist.update (context model) message model.openGist

          newModel =
            case messageToParent of
              OpenGist.Nada ->
                model

              OpenGist.SetGistState gistState ->
                { model
                | gistState = gistState
                }

              OpenGist.HandleHttpError error ->
                httpFailure model error

              OpenGist.ReceiveGistData gistData {source, variables} ->
                { model
                | gistState = Synced gistData (FileSnapshot source variables)
                , rawMarkup = source
                , variablesPanel = VariablesPanel.update
                    (VariablesPanel.SetVariables variables)
                    model.variablesPanel
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
            update
              modifyUrl
              (OpenGistMessage <| OpenGist.SetGistData gistData)
              model

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

    , Sub.map OpenGistMessage
      <| OpenGist.subscriptions model.openGist

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
            , id drawingId
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

    button markup =
      [ div
        [ class [ToolbarButton]
        ]
        markup
      ]

  in
    node "paper-header-panel"
      [ class [Root]
      , attribute "mode" "waterfall"
      ]
      <| [ node "paper-toolbar"
          [ class [Toolbar]
          ]
          <| title "parametric-svg"
          ++ button openGistButton
          ++ button saveToGistOrAuthButton

        , App.map VariablesPanelMessage (VariablesPanel.view model.variablesPanel)

        , display

        , node "codemirror-editor"
          [ class [Editor]
          , value model.rawMarkup
          , onInput UpdateRawMarkup
          ] []
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
