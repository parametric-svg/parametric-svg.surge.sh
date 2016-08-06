module Components.Auth exposing
  ( Model, Message(ReceiveToken, LoadToken)
  , init, token, update, subscriptions, view
  )

import Html exposing (Html, node, div)
import Html.Events exposing (on)
import Json.Decode as Decode exposing (Decoder, andThen)
import Http
import Task
import LocalStorage

import Components.IconButton as IconButton
import Components.Toast as Toast
import Components.Spinner as Spinner


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
  ! [ LocalStorage.get storageKey
      |> Task.perform FailToLoadToken LoadToken
    ]

token : Model -> Maybe String
token = .token


-- UPDATE

type Message
  = LoadToken (Maybe String)
  | FailToLoadToken LocalStorage.Error
  | ReceiveToken String
  | FailToReceiveToken Http.Error
  | FailToSaveToken LocalStorage.Error
  | ReceiveCode Code
  | Noop ()

type alias Code =
  Maybe String

update : Message -> Model -> (Model, Cmd Message)
update message model =
  let
    withFailure message model =
      { model
      | failureMessages = message :: model.failureMessages
      }

  in
    case message of
      LoadToken (Just token) ->
        { model
        | token = Just token
        } ! []

      LoadToken Nothing ->
        model ! []

      FailToLoadToken _ ->
        model ! []

      ReceiveToken token ->
        { model
        | token = Just token
        }
        ! [ LocalStorage.set storageKey token
            |> Task.perform FailToSaveToken Noop
          ]

      FailToSaveToken _ ->
        withFailure
          ( "Damn, we haven’t managed to save authentication details "
          ++ "for the future. Never mind though, you can keep using the app. "
          ++ "All your changes will be saved to gist as always. "
          ++ "You’ll just have to log in next time as well."
          )
          model
        ! []

      FailToReceiveToken _ ->
        withFailure "Blimey! Failed to get a github authentication token."
          { model
          | code = Nothing
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
          ! [ Task.perform FailToReceiveToken ReceiveToken fetchToken
            ]

      ReceiveCode Nothing ->
        withFailure "Yikes! Failed to get an authentication code from github."
          model
        ! []

      Noop _ ->
        model ! []


storageKey : String
storageKey =
  componentNamespace ++ "auth-key"

componentNamespace : String
componentNamespace =
  "cc2ede8-Auth-"



-- SUBSCRIPTIONS

subscriptions : Model -> Sub Message
subscriptions model =
  Sub.none


-- VIEW

view : Model -> List (Html Message)
view model =
  let
    iconButton =
      IconButton.view componentNamespace

    failureToasts =
      List.map Toast.basic <| List.reverse model.failureMessages

    staticContents =
      case (model.code, model.token) of
        (Nothing, Nothing) ->
          [ node "github-auth"
            [ onReceiveCode ReceiveCode
            ]
            <|
              iconButton
                []
                { symbol = "cloud-queue"
                , tooltip = "Enable gist integration"
                }
          ]

        (Just _, Nothing) ->
          [ div []
            <| Spinner.view "signing in with github…"
          ]

        _ ->
          []

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
