-- port module Components.OpenGist exposing
module Components.OpenGist exposing
  ( Model, MessageToParent(..), Message(SetGistData)
  , init, update
  )

-- import Html exposing (Html)
-- import Html.Events exposing (onClick, on, onInput)
-- import Html.Attributes exposing (attribute, tabindex, value, href, target)
import Json.Decode as Decode exposing (at, string, bool)
import Json.Decode.Pipeline exposing (decode, required)
import Http exposing
  ( Error(Timeout, BadResponse, UnexpectedPayload, NetworkError)
  , url
  )
import Task exposing (andThen)

import Helpers exposing ((!!))
import Types exposing (GistData, GistState(Downloading))
-- import Components.Link exposing (link)
-- import Components.IconButton as IconButton
-- import Components.Toast as Toast
-- import Components.Spinner as Spinner

-- (=>) : a -> b -> (a, b)
-- (=>) =
--   (,)




-- MODEL

type alias Model =
  {}

init : (Model, Cmd Message)
init =
  {}
  ! []




-- UPDATE

type MessageToParent
  = Nada
  | SetGistState GistState

type Message
  = SetGistData GistData
  | FailToFetchGist FetchError
  | ReceiveGist GistContent

type FetchError
  = HttpError Http.Error
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
      Task.mapError HttpError (getGist gistData)
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

-- view : Context -> Model -> List (Html Message)
-- view context model =
