port module Components.SaveToGist exposing
  ( Model, Message(UpdateMarkup, UpdateVariables)
  , init, update, subscriptions, view
  )

import Html exposing (Html)
import Html.Events exposing (onClick)
-- import Html.Attributes exposing ()
-- import Json.Decode as Decode exposing (Decoder, andThen)
-- import Http
-- import Task

import UniversalTypes exposing (Variable)
import Components.IconButton as IconButton
import Components.Toast as Toast




-- MODEL

type alias Model =
  { fileContents : Maybe String
  , markup : Markup
  , variables : List Variable
  , failureToasts : List FailureToast
  }

type alias FailureToast =
  { message : String
  , buttonText : String
  , buttonUrl : String
  }

type alias Markup =
  String

init : String -> (Model, Cmd Message)
init markup =
  { fileContents = Nothing
  , markup = markup
  , variables = []
  , failureToasts = []
  }
  ! []




-- UPDATE

type Message
  = RequestFileContents
  | ReceiveFileContents SerializationOutput
  | UpdateMarkup String
  | UpdateVariables (List Variable)

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
        }
        ! []

      (Nothing, Just failureToast) ->
        { model
        | failureToasts = failureToast :: model.failureToasts
        }
        ! []

      _ ->
        model ! []

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

  in
    iconButton
      [ onClick RequestFileContents
      ]
      { symbol = "cloud-upload"
      , tooltip = "Save as gist"
      }

    ++ toasts
