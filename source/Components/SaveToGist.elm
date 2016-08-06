port module Components.SaveToGist exposing
  ( Model, Message(UpdateMarkup, UpdateVariables)
  , init, update, subscriptions, view
  )

import Html exposing (Html, node, text, div, span)
import Html.Events exposing (onClick, on, onInput)
import Html.Attributes exposing (attribute, tabindex, value)
import Json.Decode as Decode exposing ((:=))
import Json.Encode as Encode exposing (encode)
import Http exposing
  ( Error(Timeout, BadResponse, UnexpectedPayload, NetworkError)
  )
import Task exposing (Task)

import UniversalTypes exposing (Variable)
import Components.IconButton as IconButton
import Components.Toast as Toast




-- MODEL

type alias Model =
  { fileContents : Maybe String
  , markup : Markup
  , variables : List Variable
  , failureToasts : List FailureToast
  , displayFileNameDialog : Bool
  , fileBasename : String
  , gistResponse : Maybe GistResponse
  }

type alias FailureToast =
  { message : String
  , buttonText : String
  , buttonUrl : String
  }

type alias Markup =
  String

type alias GistResponse =
  { url : String
  }

init : String -> (Model, Cmd Message)
init markup =
  { fileContents = Nothing
  , markup = markup
  , variables = []
  , failureToasts = []
  , displayFileNameDialog = False
  , fileBasename = ""
  , gistResponse = Nothing
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
  | SaveGistResponse GistResponse

  | UpdateMarkup String
  | UpdateVariables (List Variable)

type GistError
  = NoFileContents
  | HttpError Http.Error

type alias SerializationOutput =
  { payload : Maybe String
  , error : Maybe FailureToast
  }

port requestFileContents
  : {markup : Markup, variables : List Variable}
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
      model
      ! [ Task.perform FailToCreateGist SaveGistResponse <|
          sendToGist model
        ]

    SaveGistResponse gistResponse ->
      { model
      | gistResponse = Just <| Debug.log "gistResponse" gistResponse
      }
      ! []

    FailToCreateGist NoFileContents ->
      failWithMessage model <|
        "Oops! This should never happen. No file contents to send"
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


sendToGist : Model -> Task GistError GistResponse
sendToGist model =
  case model.fileContents of
    Just fileContents ->
      let
        decodeGistResponse =
          Decode.object1 GistResponse
            ("url" := Decode.string)

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
                    [ ( "contents"
                      , Encode.string fileContents
                      )
                    ]
                  )
                ]
              )
            ]

      in
        Task.mapError HttpError <|
          Http.post decodeGistResponse "https://api.github.com/gists" payload

    Nothing ->
      Task.fail NoFileContents



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

  in
    iconButton
      [ onClick RequestFileContents
      ]
      { symbol = "cloud-upload"
      , tooltip = "Save as gist"
      }

    ++ dialogs
    ++ toasts
