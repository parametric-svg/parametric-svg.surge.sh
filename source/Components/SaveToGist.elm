module Components.SaveToGist exposing
  ( Model
  , Message(UpdateMarkup, UpdateVariables, AcceptToken, AcceptFileContents)
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

import UniversalTypes exposing (Variable, ToastContent)
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
  , githubToken : Maybe String
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
  , githubToken = Nothing
  , gistId = Nothing
  , status = Void
  }
  ! []




-- UPDATE

type Message
  = AskForFileContents
  | AcceptFileContents String

  | CloseDialog

  | UpdateFileBasename String

  | CreateGist
  | FailToCreateGist GistError
  | ReceiveGistId String

  | UpdateMarkup String
  | UpdateVariables (List Variable)
  | AcceptToken String

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

    sendToGist model =
      case (model.fileContents, model.githubToken) of
        (Just fileContents, Just githubToken) ->
          Task.mapError HttpError <| saveGist githubToken fileContents

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

      AcceptFileContents fileContents ->
        { model
        | fileContents = Just fileContents
        , displayFileNameDialog = True
        }
        ! []
        !! Nada

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

      SaveGist ->
        { model
        | status = Pending
        , displayFileNameDialog = False
        }
        ! [ Task.perform FailToCreateGist ReceiveGistId <|
            sendToGist model
          ]
        !! Nada

      ReceiveGistId gistId ->
        { model
        | gistId = Just gistId
        , status = Void
        }
        ! []
        !! Nada

      FailToCreateGist NoFileContents ->
        failWithMessage <|
          "Oops! This should never happen. No file contents to send."
      FailToCreateGist NoGithubToken ->
        failWithMessage <|
          "Aw, snap! You’re not logged into gist."
      FailToCreateGist (HttpError Timeout) ->
        failWithMessage <|
          "Uh-oh! The github API request timed out. Trying again should help. " ++
          "Really."
      FailToCreateGist (HttpError NetworkError) ->
        failWithMessage <|
          "Aw, shucks! The network failed us this time. Try again in a few " ++
          "moments."
      FailToCreateGist (HttpError (UnexpectedPayload message)) ->
        failWithMessage <|
          "Huh? We don’t understand the response from the github API. " ++
          "Here’s what our decoder says: “" ++ message ++ "”."
      FailToCreateGist (HttpError (BadResponse number message)) ->
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

      AcceptToken githubToken ->
        { model
        | githubToken = Just githubToken
        }
        ! []
        !! Nada


(!!) : (a, b) -> MessageToParent -> (a, b, MessageToParent)
(!!) (model, command) messageToParent =
  (model, command, messageToParent)




-- VIEW

view : Model -> List (Html Message)
view model =
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
                  [ onTap CreateGist
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
                , tooltip = "unsaved changes – click to sync"
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
