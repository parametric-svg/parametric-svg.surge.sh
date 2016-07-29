module Components.Auth exposing
  ( Model, Message
  , init, token, update, subscriptions, view, css
  , decodeCode
  )

import Html exposing (Html, node, a, text, div)
import Html.Events exposing (on)
import Html.Attributes exposing (attribute, href, target, id)
import Html.CssHelpers exposing (withNamespace)
import Css.Namespace exposing (namespace)
import Css exposing
  ( Stylesheet
  , stylesheet, (.)
  , property
  )
import Json.Decode as Decode exposing (Decoder, andThen)
import Http
import Task

import Components.IconButton as IconButton

{class} =
  withNamespace componentNamespace


-- MODEL

type alias Model =
  { token : Maybe String
  , code : Maybe String
  , failureMessages : List String
  }

init : (Model, Cmd Message)
init =
  { token = Nothing
  , code = Nothing
  , failureMessages = []
  }
  ! []

token : Model -> Maybe String
token = .token


-- UPDATE

type Message
  = ReceiveToken String
  | FailReceivingToken Http.Error
  | ReceiveCode Code
  | Noop ()

type alias Code =
  Maybe String

update : Message -> Model -> (Model, Cmd Message)
update message model =
  case message of
    ReceiveToken token ->
      { model
      | token = Just token
      }
      ! []

    FailReceivingToken _ ->
      { model
      | code = Nothing
      , failureMessages =
        "Blimey! Failed to get a github authentication token."
        :: model.failureMessages
      }
      ! []

    ReceiveCode (Just code) ->
      let
        fetchToken =
          Http.get
            (Decode.at ["token"] Decode.string)
            ("http://parametric-svg-auth.herokuapp.com/authenticate/" ++ code)

      in
        { model
        | code = Just code
        }
        ! [ Task.perform FailReceivingToken ReceiveToken fetchToken
          ]

    ReceiveCode Nothing ->
      { model
      | failureMessages =
        "Yikes! Failed to get an authentication code from github."
        :: model.failureMessages
      }
      ! []

    Noop _ ->
      model ! []


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Message
subscriptions model =
  Sub.none


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

    staticContents =
      case (model.code, model.token) of
        (Nothing, Nothing) ->
          [ node "github-auth"
            [ onReceiveCode ReceiveCode
            ]
            <| iconButton "cloud-queue" "Enable gist integration"
          ]

        (Just _, Nothing) ->
          [ div []
            [ node "paper-spinner-lite"
              [ id spinnerId
              , attribute "active" ""
              , class [Spinner]
              ] []
            , node "paper-tooltip"
              [ attribute "for" spinnerId
              , attribute "offset" "20"
              ]
              [ text "signing in with github…"
              ]
            ]
          ]

        _ ->
          []

    spinnerId =
      componentNamespace ++ "spinner"

  in
    staticContents ++ failureToasts


onReceiveCode : (Code -> Message) -> Html.Attribute Message
onReceiveCode action =
  on "message" <| decodeCode action

decodeCode : (Code -> message) -> Decoder message
decodeCode action =
  Decode.at ["detail", "payload"] Decode.string
  |> Decode.maybe
  |> Decode.map action


-- STYLES

type Classes
  = ToastLink
  | Spinner

css : Stylesheet
css = stylesheet <| namespace componentNamespace <|
  [ (.) ToastLink
    [ property "color" "inherit"
      -- https://github.com/rtfeldman/elm-css/issues/148
    ]

  , (.) Spinner
    [ property "--paper-spinner-color" "currentColor"
    ]
  ]

componentNamespace : String
componentNamespace =
  "fe43cfb-"
