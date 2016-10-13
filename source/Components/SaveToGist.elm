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
  , GistState(NotConnected, Uploading, Synced), GistData
  )
import Components.Link exposing (link)
import Components.IconButton as IconButton
import Components.Toast as Toast
import Components.Spinner as Spinner

(=>) : a -> b -> (a, b)
(=>) =
  (,)




-- MODEL

type alias Model =
  { fileContents : Maybe String
  , toasts : List ToastContent
  , displayFileNameDialog : Bool
  , basename : String
  , status : Status
  }

type Status
  = Idle
  | Pending

init : (Model, Cmd Message)
init =
  { fileContents = Nothing
  , toasts = []
  , displayFileNameDialog = False
  , basename = ""
  , status = Idle
  }
  ! []




-- UPDATE

type MessageToParent
  = Nada
  | SetGistState GistState
  | HandleHttpError Http.Error

type Message
  = RequestFileContents Context
  | ReceiveFileContents Context FileContentsSerializationOutput

  | OpenDialog
  | CloseDialog

  | UpdateFileBasename String

  | SaveGist Context
  | ReceiveGistId Context String
  | FailToSendGist GistError

type GistError
  = NoFileContents
  | NoGithubToken
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

    failWithMessageAndButtonText message buttonText =
      { model
      | toasts = failureToast message buttonText :: model.toasts
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
      case (model.fileContents, context.githubAuthToken, context.gistState) of
        (Just fileContents, Just githubAuthToken, Synced {id} _) ->
          Task.mapError HttpError
            <| updateGist id githubAuthToken fileContents

        (Just fileContents, Just githubAuthToken, _) ->
          Task.mapError HttpError
            <| createGist githubAuthToken fileContents

        (Nothing, _, _) ->
          Task.fail NoFileContents

        (_, Nothing, _) ->
          Task.fail NoGithubToken

    updateGist token id fileContents =
      patch
        decodeGistResponse
        (githubUrl token <| "/gists/" ++ id)
        (payload fileContents [])

    createGist token fileContents =
      Http.post
        decodeGistResponse
        (githubUrl token "/gists")
        ( payload fileContents
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

    payload fileContents extraFields =
      Encode.object
        [ "files" => Encode.object
          [ fileName => Encode.object
            ( ["content" => Encode.string fileContents]
            ++ extraFields
            )
          ]
        ]
      |> encode 0
      |> Http.string

    fileName =
      model.basename ++ ".parametric.svg"

  in
    case message of
      RequestFileContents context ->
        model
        ! [ requestFileContents
            { drawingId = context.drawingId
            , variables = context.variables
            }
          ]
        !! SetGistState
          ( Uploading <| FileSnapshot context.markup context.variables
          )

      ReceiveFileContents context {payload, error} ->
        case (payload, error) of
          (_, Just failureToast) ->
            { model
            | toasts = failureToast :: model.toasts
            }
            ! []
            !! Nada

          (Just fileContents, Nothing) ->
            let
              newModel =
                { model
                | fileContents = Just fileContents
                }

            in
              case context.gistState of
                Synced _ _ ->
                  update (SaveGist context) newModel

                _ ->
                  update OpenDialog newModel

          (Nothing, Nothing) ->
            model ! [] !! Nada

      OpenDialog ->
        { model
        | displayFileNameDialog = True
        }
        ! []
        !! Nada

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

      SaveGist context ->
        { model
        | status = Pending
        , displayFileNameDialog = False
        }
        ! [ Task.perform FailToSendGist (ReceiveGistId context)
            <| saveGist context model
          ]
        !! Nada

      ReceiveGistId context id ->
        case context.gistState of
          Uploading fileSnapshot ->
            { model
            | status = Idle
            }
            ! []
            !! SetGistState
              (Synced {id = id, basename = model.basename} fileSnapshot)

          _ ->
            failWithMessageAndButtonText
              ( "Booo, things ended up in a weird state. We haven’t expected "
              ++ "this to happen. Please help us resolve this problem "
              ++ "by opening a github issue."
              )
              "Browse issues"

      FailToSendGist NoFileContents ->
        failWithMessage
          <| "Oops! This should never happen. No file contents to send."
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

    onCloseOverlay message =
      on "iron-overlay-closed" (Decode.succeed message)

    onTap message =
      on "tap" (Decode.succeed message)

    dialogs =
      if model.displayFileNameDialog
        then
          [ node "submit-on-enter" []
            [ node "paper-dialog"
              [ attribute "opened" ""
              , onCloseOverlay CloseDialog
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
                  [ onTap <| SaveGist context
                  , attribute "name" "save to gist"
                  ]
                  [ text "Save to gist"
                  ]
                ]
              ]
            ]
          ]

        else
          []

    button =
      case (model.status, context.gistState) of
        (Pending, Uploading _) ->
          Spinner.view "creating gist…"

        (Pending, Synced _ _) ->
          Spinner.view "updating gist…"

        (Idle, Synced {id, basename} fileSnapshot) ->
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
