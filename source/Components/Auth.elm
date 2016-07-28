module Components.Auth exposing
  ( Model, Message
  , init, token, update, view, css
  )

import Html exposing (Html, node, a, text)
import Html.Events exposing (on)
import Html.Attributes exposing (attribute, href, target)
import Html.CssHelpers exposing (withNamespace)
import Css.Namespace exposing (namespace)
import Css exposing
  ( Stylesheet
  , stylesheet, (.)
  , property
  )
import Json.Decode as Decode exposing (Decoder, andThen)

import Components.IconButton as IconButton

{class} =
  withNamespace componentNamespace


-- MODEL

type alias Model =
  { token : Maybe String
  , code : Maybe String
  , failureMessages : List String
  }

init : Model
init =
  { token = Nothing
  , code = Nothing
  , failureMessages = []
  }

token : Model -> Maybe String
token = .token


-- UPDATE

type Message
  = ReceiveToken String
  | ReceiveCode Code
  | Noop ()

type alias Code =
  Maybe String

update : Message -> Model -> Model
update message model =
  case message of
    ReceiveToken token ->
      { model
      | token = Just token
      }

    ReceiveCode (Just code) ->
      { model
      | code = Just code
      }

    ReceiveCode Nothing ->
      { model
      | failureMessages =
        "Yikes! Failed to get an authentication code from github."
        ::
        model.failureMessages
      }

    Noop _ ->
      model


-- VIEW

view : Model -> List (Html Message)
view model =
  let
    iconButton =
      IconButton.view Noop componentNamespace

    failureToasts =
      List.map toast <| List.reverse model.failureMessages

    toast message =
      node "paper-toast"
        [ attribute "opened" ""
        , attribute "text" message
        ]
        [ a
          [ href "https://github.com/parametric-svg/parametric-svg.surge.sh/issues"
          , target "_blank"
          , class [ToastLink]
          ]
          [ node "paper-button" []
            [ text "Get help"
            ]
          ]
        ]

  in
    case model.token of
      Just _ ->
        failureToasts

      Nothing ->
        [ node "github-auth"
          [ onReceiveCode ReceiveCode
          ]
          <| iconButton "cloud-queue" "Enable gist integration"
        ]
        ++ failureToasts

onReceiveCode : (Code -> Message) -> Html.Attribute Message
onReceiveCode action =
  on "message" <| decodeCode action

decodeCode : (Code -> message) -> Decoder message
decodeCode action =
  Decode.at ["detail", "data"] Decode.string
  |> Decode.maybe
  |> Decode.map action


-- STYLES

type Classes
  = ToastLink

css : Stylesheet
css = stylesheet <| namespace componentNamespace <|
  [ (.) ToastLink
    [ property "color" "inherit"
      -- https://github.com/rtfeldman/elm-css/issues/148
    ]
  ]

componentNamespace : String
componentNamespace =
  "fe43cfb-"
