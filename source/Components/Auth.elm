module Components.Auth exposing
  ( Model, Message, MessageToParent(Nada, UpdateToken)
  , init, update, subscriptions, view
  )

import Html exposing (Html, node, div)
import Html.Events exposing (on)
import Json.Decode as Decode exposing (Decoder, andThen)
import Http
import Task
import LocalStorage

import Helpers exposing ((!!))
import Types exposing (Context)
import Components.IconButton as IconButton
import Components.Toast as Toast
import Components.Spinner as Spinner


-- MODEL

type alias Model =
  { code : Maybe String
  , failureMessages : List String
  }

init : (Model, Cmd Message)
init =
  { code = Nothing
  , failureMessages = []
  }
  ! [ LocalStorage.get storageKey
      |> Task.perform FailToLoadToken LoadToken
    ]




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

type MessageToParent
  = Nada
  | UpdateToken (Maybe String)

update : Message -> Model -> (Model, Cmd Message, MessageToParent)
update message model =
  let
    withFailure message model =
      { model
      | failureMessages = message :: model.failureMessages
      }

  in
    case message of
      LoadToken maybeToken ->
        model ! [] !! UpdateToken maybeToken

      FailToLoadToken _ ->
        model ! [] !! Nada

      ReceiveToken token ->
        model
        ! [ LocalStorage.set storageKey token
            |> Task.perform FailToSaveToken Noop
          ]
        !! UpdateToken (Just token)

      FailToSaveToken _ ->
        withFailure
          ( "Damn, we haven’t managed to save authentication details "
          ++ "for the future. Never mind though, you can keep using the app. "
          ++ "All your changes will be saved to gist as always. "
          ++ "You’ll just have to log in next time as well."
          )
          model
        ! []
        !! Nada

      FailToReceiveToken _ ->
        withFailure "Blimey! Failed to get a github authentication token."
          { model
          | code = Nothing
          }
        ! []
        !! Nada

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
          !! Nada

      ReceiveCode Nothing ->
        withFailure "Yikes! Failed to get an authentication code from github."
          model
        ! []
        !! Nada

      Noop _ ->
        model ! [] !! Nada


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

view : Context -> Model -> List (Html Message)
view context model =
  let
    iconButton =
      IconButton.view componentNamespace

    failureToasts =
      List.map Toast.basic <| List.reverse model.failureMessages

    staticContents =
      case (model.code, context.githubAuthToken) of
        (Nothing, Nothing) ->
          [ node "github-auth"
            [ onReceiveCode ReceiveCode
            ]
            <|
              iconButton
                []
                { symbol = "cloud-queue"
                , tooltip = "enable gist integration"
                }
          ]

        (Just _, Nothing) ->
          Spinner.view "signing in with github…"

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
