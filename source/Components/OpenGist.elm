-- port module Components.OpenGist exposing
module Components.OpenGist exposing
  ( Model, MessageToParent(..), Message(SetGistId)
  , init, update
  )

-- import Html exposing (Html)
-- import Html.Events exposing (onClick, on, onInput)
-- import Html.Attributes exposing (attribute, tabindex, value, href, target)
-- import Json.Decode as Decode exposing ((:=))
-- import Json.Encode as Encode exposing (encode)
-- import Http exposing
--   ( Error(Timeout, BadResponse, UnexpectedPayload, NetworkError)
--   , url
--   )
-- import Task exposing (Task)

import Helpers exposing ((!!))
import Types exposing (GistId, GistState(Downloading))
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
  = SetGistId GistId

update : Message -> Model -> (Model, Cmd Message, MessageToParent)
update message model =
  case message of
    SetGistId gistId ->
      model
      ! []
      !! SetGistState (Downloading gistId)




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
