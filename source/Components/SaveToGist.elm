port module Components.SaveToGist exposing
  ( Model, Message(UpdateMarkup, UpdateVariables, PassToken)
  , init, update, subscriptions, view
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

import UniversalTypes exposing (Variable)
import Components.Link exposing (link)
import Components.IconButton as IconButton
import Components.Toast as Toast




-- MODEL

type alias Model =
  { fileContents : Maybe String
  , markup : String
  , variables : List Variable
  , failureToasts : List FailureToast
  , displayFileNameDialog : Bool
  , fileBasename : String
  , markupSnapshot : Maybe String
  , githubToken : Maybe String
  , gistId : Maybe String
  }

type alias FailureToast =
  { message : String
  , buttonText : String
  , buttonUrl : String
  }

init : String -> (Model, Cmd Message)
init markup =
  { fileContents = Nothing
  , markup = markup
  , variables = []
  , failureToasts = []
  , displayFileNameDialog = False
  , fileBasename = ""
  , markupSnapshot = Nothing
  , githubToken = Nothing
  , gistId = Nothing
  }
  ! []




-- UPDATE

type Message
  = RequestFileContents
  | ReceiveFileContents SerializationOutput

  | CloseDialog

  | UpdateFileBasename String

  | CreateGist
  | FailToCreateGist GistError
  | ReceiveGistId String

  | UpdateMarkup String
  | UpdateVariables (List Variable)
  | PassToken String

type GistError
  = NoFileContents
  | NoGithubToken
  | HttpError Http.Error

type alias SerializationOutput =
  { payload : Maybe String
  , error : Maybe FailureToast
  }

port requestFileContents
  : {markup : String, variables : List Variable}
  -> Cmd message

update : Message -> Model -> (Model, Cmd Message)
update message model =
  case message of
    RequestFileContents ->
      model
      ! [ requestFileContents
          { markup = model.markup
          , variables = model.variables
          }
        ]

    ReceiveFileContents {payload, error} -> case (payload, error) of
      (Just fileContents, Nothing) ->
        { model
        | fileContents = Just fileContents
        , displayFileNameDialog = True
        }
        ! []

      (Nothing, Just failureToast) ->
        { model
        | failureToasts = failureToast :: model.failureToasts
        }
        ! []

      _ ->
        model ! []

    CloseDialog ->
      { model
      | displayFileNameDialog = False
      }
      ! []

    UpdateFileBasename fileBasename ->
      { model
      | fileBasename = fileBasename
      }
      ! []

    CreateGist ->
      { model
      | markupSnapshot = Just model.markup
      }
      ! [ Task.perform FailToCreateGist ReceiveGistId <|
          sendToGist model
        ]

    ReceiveGistId gistId ->
      { model
      | gistId = Just gistId
      }
      ! []

    FailToCreateGist NoFileContents ->
      failWithMessage model <|
        "Oops! This should never happen. No file contents to send."
    FailToCreateGist NoGithubToken ->
      failWithMessage model <|
        "Aw, snap! You’re not logged into gist."
    FailToCreateGist (HttpError Timeout) ->
      failWithMessage model <|
        "Uh-oh! The github API request timed out. Trying again should help. " ++
        "Really."
    FailToCreateGist (HttpError NetworkError) ->
      failWithMessage model <|
        "Aw, shucks! The network failed us this time. Try again in a few " ++
        "moments."
    FailToCreateGist (HttpError (UnexpectedPayload message)) ->
      failWithMessage model <|
        "Huh? We don’t understand the response from the github API. " ++
        "Here’s what our decoder says: “" ++ message ++ "”."
    FailToCreateGist (HttpError (BadResponse number message)) ->
      failWithMessage model <|
        "Yikes! The github API responded " ++
        "with a " ++ toString number ++ " error. " ++
        "Here’s what they say: “" ++ message ++ "”."

    UpdateMarkup markup ->
      { model
      | markup = markup
      }
      ! []

    UpdateVariables variables ->
      { model
      | variables = variables
      }
      ! []

    PassToken githubToken ->
      { model
      | githubToken = Just githubToken
      }
      ! []


failWithMessage : Model -> String -> (Model, Cmd Message)
failWithMessage model message =
  let
    failureToast =
      { message = message
      , buttonText = "Get help"
      , buttonUrl =
        "https://github.com/parametric-svg/parametric-svg.surge.sh/issues"
      }

  in
    { model
    | failureToasts = failureToast :: model.failureToasts
    }
    ! []


sendToGist : Model -> Task GistError String
sendToGist model =
  case (model.fileContents, model.githubToken) of
    (Just fileContents, Just githubToken) ->
      let
        decodeGistResponse =
          ("id" := Decode.string)

        payload =
          serializedModel
          |> encode 0
          |> Http.string

        serializedModel =
          Encode.object
            [ ( "files"
              , Encode.object
                [ ( model.fileBasename ++ ".parametric.svg"
                  , Encode.object
                    [ ( "content"
                      , Encode.string fileContents
                      )
                    ]
                  )
                ]
              )
            ]

      in
        Task.mapError HttpError <|
          Http.post
            decodeGistResponse
            (url "https://api.github.com/gists" [("access_token", githubToken)])
            payload

    (Nothing, _) ->
      Task.fail NoFileContents

    (_, Nothing) ->
      Task.fail NoGithubToken



-- SUBSCRIPTIONS

port fileContents : (SerializationOutput -> message) -> Sub message

subscriptions : Model -> Sub Message
subscriptions model =
  fileContents ReceiveFileContents




-- VIEW

view : Model -> List (Html Message)
view model =
  let
    iconButton =
      IconButton.view componentNamespace

    componentNamespace =
      "d34616d-SaveToGist-"

    toasts =
      List.reverse model.failureToasts
        |> List.map Toast.custom

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
      case (model.gistId, model.markupSnapshot) of
        (Just gistId, Just markupSnapshot) ->
          if model.markup == markupSnapshot
            then
              [ link
                [ href <| "https://gist.github.com/" ++ gistId
                , target "_blank"
                , tabindex -1
                ]
                <| iconButton []
                  { symbol = "check"
                  , tooltip = "Saved – click to view"
                  }
              ]

            else
              iconButton
                [ onClick RequestFileContents
                ]
                { symbol = "save"
                , tooltip = "Unsaved changes – click to sync"
                }

        _ ->
          iconButton
            [ onClick RequestFileContents
            ]
            { symbol = "cloud-upload"
            , tooltip = "Save as gist"
            }

  in
    button
    ++ dialogs
    ++ toasts
