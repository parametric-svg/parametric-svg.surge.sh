port module Components.SaveToGist exposing
  ( Model, MessageToParent(..), Message
  , init, update, subscriptions, view
  )

import Html exposing (Html, node, text, div, span, a)
import Html.Events exposing (onClick, on, onInput)
import Html.Attributes exposing (attribute, tabindex, value, href, target)
import Json.Decode as Decode exposing ((:=))
import Json.Encode as Encode exposing (encode)
import Http exposing (url)
import Task exposing (Task)

import Helpers exposing ((!!))
import Types exposing
  ( Variable, ToastContent, Context, FileSnapshot
  , GistState(NotConnected, Uploading, Syncing, Synced), GistData
  )
import Components.Link exposing (link)
import Components.IconButton as IconButton
import Components.Toast as Toast
import Components.Spinner as Spinner
import Components.Dialog as Dialog exposing
  ( onCloseOverlay
  , dialog
  )

(=>) : a -> b -> (a, b)
(=>) =
  (,)




-- MODEL

type alias Model =
  { toasts : List ToastContent
  , displayFileNameDialog : Bool
  , basename : String
  }

init : (Model, Cmd Message)
init =
  { toasts = []
  , displayFileNameDialog = False
  , basename = ""
  }
  ! []




-- UPDATE

type MessageToParent
  = Nada
  | SetGistState GistState
  | SetGistStateAndMarkup GistState String
  | SetMarkup String
  | HandleHttpError Http.Error

type Message
  = RequestFileContents Context
  | ReceiveFileContents Context FileContentsSerializationOutput

  | OpenDialog Markup
  | CloseDialog

  | UpdateFileBasename String

  | SaveGist Context Markup
  | ReceiveGistId GistState String
  | FailToSendGist GistError

type alias Markup =
  String

type GistError
  = NoGithubToken
  | HttpError Http.Error

type alias FileContentsSerializationOutput =
  { payload : Maybe String
  , error : Maybe ToastContent
  }

update : Message -> Model -> (Model, Cmd Message, MessageToParent)
update message model =
  let
    failWithMessage message =
      { model
      | toasts = failureToast message "Get help" :: model.toasts
      }
      ! []
      !! SetGistState NotConnected

    failureToast message buttonText =
      { message = message
      , buttonText = buttonText
      , buttonUrl =
        "https://github.com/parametric-svg/parametric-svg.surge.sh/issues"
      , openInNewTab = True
      }

    saveGist context model =
      case (context.githubAuthToken, context.gistState) of
        (Just githubAuthToken, Synced {id} _) ->
          Task.mapError HttpError
            <| updateGist context githubAuthToken id context.markup

        (Just githubAuthToken, _) ->
          Task.mapError HttpError
            <| createGist context githubAuthToken context.markup

        (Nothing, _) ->
          Task.fail NoGithubToken

    updateGist context token id fileContents =
      patch
        decodeGistResponse
        (githubUrl token <| "/gists/" ++ id)
        (payload context fileContents [])

    createGist context token fileContents =
      Http.post
        decodeGistResponse
        (githubUrl token "/gists")
        ( payload context fileContents
          [ "description" =>
            Encode.string "Created with parametric-svg.surge.sh"
          ]
        )

    patch decoder url body =
      Http.fromJson decoder <| Http.send Http.defaultSettings
        { verb = "PATCH"
        , headers = []
        , url = url
        , body = body
        }

    githubUrl token path =
      url ("https://api.github.com" ++ path) ["access_token" => token]

    decodeGistResponse =
      ("id" := Decode.string)

    payload context fileContents extraFields =
      Encode.object
        [ "files" => Encode.object
          [ fileName context => Encode.object
            ( ["content" => Encode.string fileContents]
            ++ extraFields
            )
          ]
        ]
      |> encode 0
      |> Http.string

    fileName context =
      let fileBasename =
        case context.gistState of
          Synced {basename} _ ->
            basename

          Syncing {basename} _ ->
            basename

          _ ->
            model.basename

      in
        fileBasename ++ ".parametric.svg"

  in
    case message of
      RequestFileContents context ->
        model
        ! [ requestFileContents
            { drawingId = context.drawingId
            , variables = context.variables
            }
          ]
        !! Nada

      ReceiveFileContents context {payload, error} ->
        case (payload, error) of
          (_, Just failureToast) ->
            { model
            | toasts = failureToast :: model.toasts
            }
            ! []
            !! Nada

          (Just fileContents, Nothing) ->
            case context.gistState of
              Synced _ _ ->
                update (SaveGist context fileContents) model

              _ ->
                update (OpenDialog fileContents) model

          (Nothing, Nothing) ->
            model ! [] !! Nada

      OpenDialog markup ->
        { model
        | displayFileNameDialog = True
        }
        ! []
        !! SetMarkup markup

      CloseDialog ->
        { model
        | displayFileNameDialog = False
        }
        ! []
        !! Nada

      UpdateFileBasename basename ->
        { model
        | basename = basename
        }
        ! []
        !! Nada

      SaveGist context markup ->
        let
          gistState =
            case context.gistState of
              Synced gistData _ ->
                Syncing gistData fileSnapshot

              _ ->
                Uploading fileSnapshot

          fileSnapshot =
            (FileSnapshot markup context.variables)


        in
          { model
          | displayFileNameDialog = False
          }
          ! [ Task.perform FailToSendGist (ReceiveGistId gistState)
              <| saveGist context model
            ]
          !! SetGistStateAndMarkup gistState markup

      ReceiveGistId gistState id ->
        case gistState of
          Uploading fileSnapshot ->
            model
            ! []
            !! SetGistState
              (Synced {id = id, basename = model.basename} fileSnapshot)

          Syncing gistData fileSnapshot ->
            model
            ! []
            !! SetGistState
              (Synced gistData fileSnapshot)

          _ ->
            { model
            | toasts = Toast.pleaseReportThis :: model.toasts
            }
            ! []
            !! SetGistState NotConnected

      FailToSendGist NoGithubToken ->
        failWithMessage
          <| "Aw, snap! You’re not logged into gist."
      FailToSendGist (HttpError error) ->
        model
        ! []
        !! HandleHttpError error


port requestFileContents
  : {drawingId : String, variables : List Variable}
  -> Cmd message




-- SUBSCRIPTIONS

subscriptions : Context -> Model -> Sub Message
subscriptions context model =
  fileContents (ReceiveFileContents context)

port fileContents
  : (FileContentsSerializationOutput -> message)
  -> Sub message





-- VIEW

view : Context -> Model -> List (Html Message)
view context model =
  let
    iconButton =
      IconButton.view componentNamespace

    componentNamespace =
      "d34616d-SaveToGist-"

    onTap message =
      on "tap" (Decode.succeed message)

    dialogs =
      if model.displayFileNameDialog
        then
          [ dialog
            [ onCloseOverlay CloseDialog
            ]
            [ node "focus-on-mount" []
              [ node "paper-input"
                [ attribute "label" "enter a file name"
                , attribute "name" "file name"
                , tabindex 0
                , onInput UpdateFileBasename
                , value model.basename
                ]
                [ div
                  [ attribute "suffix" ""
                  ]
                  [ text ".parametric.svg"
                  ]
                ]
              ]
            , div
              [ Html.Attributes.class "buttons"
              ]
              [ node "paper-button"
                [ onTap <| SaveGist context context.markup
                , attribute "name" "save to gist"
                ]
                [ text "Save to gist"
                ]
              ]
            ]
          ]

        else
          []

    button =
      case context.gistState of
        Uploading _ ->
          Spinner.view "creating gist…"

        Syncing _ _ ->
          Spinner.view "updating gist…"

        Synced {id, basename} fileSnapshot ->
          if (context.markup == fileSnapshot.markup)
          && (context.variables == fileSnapshot.variables)
            then
              [ link
                [ href
                  <| "https://gist.github.com/" ++ id ++ "#file-" ++ basename
                , target "_blank"
                , tabindex -1
                ]
                <| iconButton []
                  { symbol = "check"
                  , tooltip = "saved – click to view"
                  }
              ]

            else
              iconButton
                [ onClick (RequestFileContents context)
                ]
                { symbol = "save"
                , tooltip = "unsaved changes – click to save"
                }

        _ ->
          iconButton
            [ onClick (RequestFileContents context)
            ]
            { symbol = "cloud-upload"
            , tooltip = "save as gist"
            }

  in
    button
    ++ dialogs
    ++ Toast.toasts model
