port module Components.OpenGist exposing
  ( Model, MessageToParent(..), Message(SetGistData)
  , init, update, subscriptions, view
  )

import Html exposing (Html, h2, node, div, text)
import Html.Events exposing (onClick)
import Html.Attributes exposing (attribute)
import Json.Decode as Decode exposing (at, string, bool)
import Json.Decode.Pipeline exposing (decode, required)
import Http exposing (Error(BadResponse))
import Task exposing (andThen)

import Helpers exposing ((!!))
import Types exposing
  ( Context, GistData, GistState(Downloading, NotFound, Synced, NotConnected)
  , ToastContent, Variable
  )
import Components.IconButton as IconButton
import Components.Toast as Toast
import Components.Spinner as Spinner
import Components.Dialog as Dialog exposing
  ( onCloseOverlay
  , dialog
  )




-- MODEL

type alias Model =
  { toasts : List ToastContent
  , dialogState : DialogState
  }

type DialogState
  = Hidden
  | LoadingData

init : (Model, Cmd Message)
init =
  { toasts = []
  , dialogState = Hidden
  }
  ! []




-- UPDATE

type MessageToParent
  = Nada
  | SetGistState GistState
  | HandleHttpError Http.Error
  | ReceiveGistData
    GistData
    { source : String
    , variables : List Variable
    }

type Message
  = SetGistData GistData
  | FailToFetchGist FetchError
  | ReceiveGist GistContent
  | ReceiveParsedFile ParsedFile

  | OpenDialog
  | CloseDialog
  | ReceiveListOfGists (List GistData)

type FetchError
  = HttpError GistData Http.Error
  | GistTruncated

type alias GistContent
  = String

type alias ParsedFile =
  { source : String
  , variables : List Variable
  }

type alias GistFileContents =
  { content : GistContent
  , truncated : Bool
  }

update : Context -> Message -> Model -> (Model, Cmd Message, MessageToParent)
update context message model =
  let
    fetchGist gistData =
      Task.mapError (HttpError gistData) (getGist gistData)
      `andThen`
      ensureNotTruncated

    getGist {id, basename} =
      Http.get
        (decodeGistFile <| basename ++ ".parametric.svg")
        ("https://api.github.com/gists/" ++ id)

    decodeGistFile basename =
      at ["files", basename]
        ( decode GistFileContents
          |> required "content" string
          |> required "truncated" bool
        )

    ensureNotTruncated {content, truncated} =
      if truncated
        then Task.fail GistTruncated
        else Task.succeed content

    hint toast =
      { model
      | toasts = toast :: model.toasts
      }
      ! []
      !! Nada

    receiveGistData gistData {source, variables} =
      model
      ! []
      !! ReceiveGistData gistData {source = source, variables = variables}

  in
    case (message, context.gistState) of
      (SetGistData gistData, Synced _ _) ->
        model
        ! []
        !! Nada

      (SetGistData gistData, _) ->
        model
        ! [ Task.perform FailToFetchGist ReceiveGist
            <| fetchGist gistData
          ]
        !! SetGistState (Downloading gistData)


      (FailToFetchGist (HttpError {id} (BadResponse 404 _)), _) ->
        { model
        | toasts =
          { message =
            ( "Sir, we’ve searched the whole place! We can’t find the gist "
            ++ "you’ve asked for though. Make sure the gist ID "
            ++ "in the current URL (" ++ id ++ ") matches an actual gist."
            )
          , buttonText = "see on github"
          , buttonUrl = "https://gist.github.com/" ++ id
          , openInNewTab = True
          } :: model.toasts
        }
        ! []
        !! SetGistState NotFound

      (FailToFetchGist GistTruncated, _) ->
        hint <| Toast.getHelp
          ( "Yikes! This looks like a really long gist. At the moment "
          ++ "we only support gists up to 1 MB in size. If you need support "
          ++ "for larger files, let us know."
          )

      (FailToFetchGist (HttpError _ error), _) ->
        model
        ! []
        !! HandleHttpError error


      (ReceiveGist content, _) ->
        model
        ! [ requestParsedFile content
          ]
        !! Nada


      (ReceiveParsedFile parsedFile, Downloading gistData) ->
        receiveGistData gistData parsedFile

      (ReceiveParsedFile parsedFile, Synced gistData _) ->
        receiveGistData gistData parsedFile

      (ReceiveParsedFile _, _) ->
        hint Toast.pleaseReportThis


      (OpenDialog, _) ->
        { model
        | dialogState = LoadingData
        }
        ! []
        !! Nada


      (CloseDialog, _) ->
        { model
        | dialogState = Hidden
        }
        ! []
        !! Nada


      (ReceiveListOfGists _, _) ->
        Debug.crash "not implemented"


port requestParsedFile
  : GistContent
  -> Cmd message




-- SUBSCRIPTIONS

subscriptions : Model -> Sub Message
subscriptions model =
  receiveParsedFile ReceiveParsedFile

port receiveParsedFile
  : (ParsedFile -> message)
  -> Sub message





-- VIEW

view : Context -> Model -> List (Html Message)
view context model =
  let
    button =
      case context.gistState of
        Downloading _ ->
          Spinner.view "downloading gist…"

        NotConnected ->
          iconButton
            [ onClick OpenDialog
            ]
            { symbol = "folder"
            , tooltip = "open gist"
            }

        _ ->
          []

    iconButton =
      IconButton.view componentNamespace

    componentNamespace =
      "c7a7bd2-OpenGist-"

    dialogs =
      case model.dialogState of
        Hidden ->
          []

        LoadingData ->
          [ dialog
            [ onCloseOverlay CloseDialog
            ]
            [ h2 []
              [ text "open gist"
              ]
            , node "paper-dialog-scrollable" []
              ( List.repeat 20
                <| node "paper-item" []
                  [ node "paper-item-body"
                    [ attribute "two-line" ""
                    ]
                    [ node "mock-text" [] []
                    , div
                      [ attribute "secondary" ""
                      ]
                      [ node "mock-text" [] []
                      ]
                    ]
                  ]
              )
            ]
          ]

  in
    button
    ++ dialogs
    ++ Toast.toasts model
