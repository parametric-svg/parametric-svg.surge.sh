-- port module Components.OpenGist exposing
module Components.OpenGist exposing
  ( Model, MessageToParent(..), Message(SetGistData)
  , init, update, view
  )

import Html exposing (Html)
import Json.Decode as Decode exposing (at, string, bool)
import Json.Decode.Pipeline exposing (decode, required)
import Http exposing (Error(BadResponse))
import Task exposing (andThen)

import Helpers exposing ((!!))
import Types exposing
  ( Context, GistData, GistState(Downloading, NotFound), ToastContent
  )
-- import Components.Link exposing (link)
-- import Components.IconButton as IconButton
import Components.Toast as Toast
import Components.Spinner as Spinner

-- (=>) : a -> b -> (a, b)
-- (=>) =
--   (,)




-- MODEL

type alias Model =
  { toasts : List ToastContent
  }

init : (Model, Cmd Message)
init =
  { toasts = []
  }
  ! []




-- UPDATE

type MessageToParent
  = Nada
  | SetGistState GistState
  | HandleHttpError Http.Error

type Message
  = SetGistData GistData
  | FailToFetchGist FetchError
  | ReceiveGist GistContent

type FetchError
  = HttpError GistData Http.Error
  | GistTruncated

type alias GistContent
  = String

type alias GistFileContents =
  { content : GistContent
  , truncated : Bool
  }

update : Message -> Model -> (Model, Cmd Message, MessageToParent)
update message model =
  let
    fetchGist gistData =
      Task.mapError (HttpError gistData) (getGist gistData)
      `andThen`
      ensureNotTruncated

    getGist {id, basename} =
      Http.get
        (decodeGistFile basename)
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

  in
    case message of
      SetGistData gistData ->
        model
        ! [ Task.perform FailToFetchGist ReceiveGist
            <| fetchGist gistData
          ]
        !! SetGistState (Downloading gistData)

      FailToFetchGist (HttpError {id} (BadResponse 404 _)) ->
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

      FailToFetchGist (HttpError _ error) ->
        model
        ! []
        !! HandleHttpError error

      _ ->
        Debug.crash <| "TODO" ++ toString message




-- SUBSCRIPTIONS

-- subscriptions : Context -> Model -> Sub Message
-- subscriptions context model =
--   fileContents (ReceiveFileContents context)
--
-- port fileContents
--   : (FileContentsSerializationOutput -> message)
--   -> Sub message





-- VIEW

view : Context -> Model -> List (Html Message)
view context model =
  let
    button =
      case context.gistState of
        Downloading _ ->
          Spinner.view "downloading gist…"

        _ ->
          []

  in
    button
    ++ Toast.toasts model
