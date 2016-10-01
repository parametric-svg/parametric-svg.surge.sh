module Components.SaveToGist exposing
  ( Model
  , Message(UpdateMarkup, UpdateVariables, AcceptFileContents)
  , MessageToParent(..)

  , init, update, view
  )

import Html exposing (Html, node, text, div, span, a)
import Html.Events exposing (onClick, on, onInput)
import Html.Attributes exposing (attribute, tabindex, value, href, target)
import Json.Decode as Decode exposing ((:=))
import Json.Encode as Encode exposing (encode)
import Http exposing
  ( Error(Timeout, BadResponse, UnexpectedPayload, NetworkError)
  , url
  )
import Task exposing (Task)

import Helpers exposing ((!!))
import Types exposing (Variable, ToastContent, Context)
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
  , markup : String
  , variables : List Variable
  , toasts : List ToastContent
  , displayFileNameDialog : Bool
  , fileBasename : String
  , dataSnapshot : Maybe DataSnapshot
  , gistId : Maybe String
  , status : Status
  }

type alias DataSnapshot =
  { markup : String
  , variables : List Variable
  }

type Status
  = Void
  | Pending

init : String -> (Model, Cmd Message)
init markup =
  { fileContents = Nothing
  , markup = markup
  , variables = []
  , toasts = []
  , displayFileNameDialog = False
  , fileBasename = ""
  , dataSnapshot = Nothing
  , gistId = Nothing
  , status = Void
  }
  ! []




-- UPDATE

type Message
  = AskForFileContents
  | AcceptFileContents Context String

  | CloseDialog

  | UpdateFileBasename String

  | SaveGist Context
  | ReceiveGistId String
  | FailToSendGist GistError

  | UpdateMarkup String
  | UpdateVariables (List Variable)

type GistError
  = NoFileContents
  | NoGithubToken
  | HttpError Http.Error

type MessageToParent
  = Nada
  | FileContentsPlease

update : Message -> Model -> (Model, Cmd Message, MessageToParent)
update message model =
  let
    failWithMessage message =
      { model
      | toasts = failureToast message :: model.toasts
      }
      ! []
      !! Nada

    failureToast message =
      { message = message
      , buttonText = "Get help"
      , buttonUrl =
        "https://github.com/parametric-svg/parametric-svg.surge.sh/issues"
      }

    sendToGist context model =
      case (model.fileContents, context.githubAuthToken) of
        (Just fileContents, Just githubAuthToken) ->
          Task.mapError HttpError <| saveGist githubAuthToken fileContents

        (Nothing, _) ->
          Task.fail NoFileContents

        (_, Nothing) ->
          Task.fail NoGithubToken

    saveGist token fileContents =
      case model.gistId of
        Just gistId ->
          patch
            decodeGistResponse
            (githubUrl token <| "/gists/" ++ gistId)
            (payload fileContents [])

        Nothing ->
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
      model.fileBasename ++ ".parametric.svg"

  in
    case message of
      AskForFileContents ->
        { model
        | dataSnapshot = Just (DataSnapshot model.markup model.variables)
        }
        ! []
        !! FileContentsPlease

      AcceptFileContents context fileContents ->
        case model.gistId of
          Nothing ->
            { model
            | fileContents = Just fileContents
            , displayFileNameDialog = True
            }
            ! []
            !! Nada

          Just _ ->
            let
              newModel =
                { model
                | fileContents = Just fileContents
                }

            in
              update (SaveGist context) newModel

      CloseDialog ->
        { model
        | displayFileNameDialog = False
        }
        ! []
        !! Nada

      UpdateFileBasename fileBasename ->
        { model
        | fileBasename = fileBasename
        }
        ! []
        !! Nada

      SaveGist context ->
        { model
        | status = Pending
        , displayFileNameDialog = False
        }
        ! [ Task.perform FailToSendGist ReceiveGistId <|
            sendToGist context model
          ]
        !! Nada

      ReceiveGistId gistId ->
        { model
        | gistId = Just gistId
        , status = Void
        }
        ! []
        !! Nada

      FailToSendGist NoFileContents ->
        failWithMessage <|
          "Oops! This should never happen. No file contents to send."
      FailToSendGist NoGithubToken ->
        failWithMessage <|
          "Aw, snap! You’re not logged into gist."
      FailToSendGist (HttpError Timeout) ->
        failWithMessage <|
          "Uh-oh! The github API request timed out. Trying again should help. " ++
          "Really."
      FailToSendGist (HttpError NetworkError) ->
        failWithMessage <|
          "Aw, shucks! The network failed us this time. Try again in a few " ++
          "moments."
      FailToSendGist (HttpError (UnexpectedPayload message)) ->
        failWithMessage <|
          "Huh? We don’t understand the response from the github API. " ++
          "Here’s what our decoder says: “" ++ message ++ "”."
      FailToSendGist (HttpError (BadResponse number message)) ->
        failWithMessage <|
          "Yikes! The github API responded " ++
          "with a " ++ toString number ++ " error. " ++
          "Here’s what they say: “" ++ message ++ "”."

      UpdateMarkup markup ->
        { model
        | markup = markup
        }
        ! []
        !! Nada

      UpdateVariables variables ->
        { model
        | variables = variables
        }
        ! []
        !! Nada




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
                  , value model.fileBasename
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
      case (model.status, model.gistId, model.dataSnapshot) of
        (Pending, Nothing, _) ->
          Spinner.view "creating gist…"

        (Pending, Just _, _) ->
          Spinner.view "updating gist…"

        (Void, Just gistId, Just snapshot) ->
          if (model.markup == snapshot.markup)
          && (model.variables == snapshot.variables)
            then
              [ link
                [ href <| "https://gist.github.com/" ++ gistId
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
                [ onClick AskForFileContents
                ]
                { symbol = "save"
                , tooltip = "unsaved changes – click to save"
                }

        _ ->
          iconButton
            [ onClick AskForFileContents
            ]
            { symbol = "cloud-upload"
            , tooltip = "save as gist"
            }

  in
    button
    ++ dialogs
    ++ Toast.toasts model
