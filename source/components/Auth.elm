module Auth exposing
  ( Model, Message
  , init, token, update, view
  ,decodeToken
  )

import Html exposing (node, Html)
import Html.Events
import Json.Decode as Decode exposing (Decoder)


-- MODEL

type alias Model =
  { token : Maybe String
  }

init : Model
init =
  { token = Nothing
  }

token : Model -> Maybe String
token = .token


-- UPDATE

type Message
  = ReceiveToken String

update : Message -> Model -> Model
update message model =
  case message of
    ReceiveToken token ->
      { model
      | token = Just token
      }


-- VIEW

view : Model -> List (Html Message) -> List (Html Message)
view model contents =
  case model.token of
    Just _ ->
      contents

    Nothing ->
      [ node "github-auth"
        [ onToken ReceiveToken
        ]
        contents
      ]

onToken : (String -> message) -> Html.Attribute message
onToken message =
  Html.Events.on "token" <| decodeToken message

decodeToken : (String -> message) -> Decoder message
decodeToken message =
  Decode.at ["detail", "token"] Decode.string
  `Decode.andThen`
  \token -> Decode.succeed <| message (Debug.log "token" token)
