port module Components.SaveToGist exposing
  ( Model, Message
  , init, update, subscriptions, view
  )

import Html exposing (Html)
-- import Html.Attributes exposing ()
-- import Json.Decode as Decode exposing (Decoder, andThen)
-- import Http
-- import Task

import UniversalTypes exposing (Variable)
import Components.IconButton as IconButton




-- MODEL

type alias Model =
  { fileContents : Maybe String
  , markup : Markup
  , variables : List Variable
  }

type alias Markup =
  String

init : (Model, Cmd Message)
init =
  { fileContents = Nothing
  , markup = ""
  , variables = []
  }
  ! []




-- UPDATE

type Message
  = RequestFileContents
  | ReceiveFileContents String
  | Noop ()

port requestFileContents : (Markup, List Variable) -> Cmd message

update : Message -> Model -> (Model, Cmd Message)
update message model =
  case message of
    RequestFileContents ->
      model
      ! [ requestFileContents (model.markup, model.variables)
        ]

    ReceiveFileContents fileContents ->
      { model
      | fileContents = Just <| Debug.log "fileContents" fileContents
      }
      ! []

    Noop _ ->
      model ! []




-- SUBSCRIPTIONS

port fileContents : (String -> message) -> Sub message

subscriptions : Model -> Sub Message
subscriptions model =
  fileContents ReceiveFileContents




-- VIEW

view : Model -> List (Html Message)
view model =
  let
    iconButton =
      IconButton.view Noop componentNamespace

    componentNamespace =
      "d34616d-SaveToGist-"

  in
    iconButton "cloud-upload" "Save as gist"
