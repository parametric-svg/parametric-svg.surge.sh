module Components.VariablesPanel exposing
  ( Model, Message
  , init, update, view
  , variables
  )

import Dict exposing (empty, Dict)
import Html exposing (div, node, Html)
import Html.Attributes exposing (attribute)
import Html.Events exposing (onInput)
import Html.CssHelpers exposing (withNamespace)

import UniversalTypes exposing (Variable)
import Styles.VariablesPanel exposing
  ( Classes(Root, Input, InputField, Parameter, Value)
  , componentNamespace
  )

{class} =
  withNamespace componentNamespace


-- MODEL

type alias Model =
  { variableFields : Dict Id VariableField
  , nextId : Id
  }

type alias VariableField =
  { name : Maybe String
  , value : Maybe String
  }

type alias Id =
  Int

init : Model
init =
  Model
    (Dict.fromList [emptyVariableField 0])
    1


variables : Model -> List Variable
variables { variableFields } =
  let
    toVariable field =
      case (field.name, field.value) of
        (Just name, Just value) ->
          Just {name = name, value = value}
        _ ->
          Nothing
  in
    Dict.values variableFields
    |> List.filterMap toVariable


emptyVariableField : Id -> (Id, VariableField)
emptyVariableField id =
  (id, VariableField Nothing Nothing)


-- ACTIONS

type Message
  = UpdateVariableName Id String
  | UpdateVariableValue Id String

update : Message -> Model -> Model
update message model =
  let
    updateName name variable =
      {variable | name =
        if name == ""
          then Nothing
          else Just name
      }

    updateValue value variable =
      {variable | value =
        if value == ""
          then Nothing
          else Just value
      }

    normalizeVariableFields fields =
      Dict.fromList
      <| List.filter notEmpty (Dict.toList fields)
      ++ [emptyVariableField model.nextId]

    notEmpty (_, fieldData) =
      if fieldData == {name = Nothing, value = Nothing}
        then False
        else True

    updateVariableFields id updater =
      { model
      | variableFields =
        normalizeVariableFields
        <| Dict.update id (Maybe.map updater) model.variableFields
      , nextId =
        model.nextId + 1
      }

  in
    case message of
      UpdateVariableName id name ->
        updateVariableFields id (updateName name)

      UpdateVariableValue id value ->
        updateVariableFields id (updateValue value)


-- VIEW

view : Model -> Html Message
view model =
  let
    renderVariableField (id, field) =
      div
        [ class [Input]
        ]
        [ node "paper-input"
          [ value <| field.name
          , label "parameter"
          , class [InputField, Parameter]
          , onInput (UpdateVariableName id)
          ] []
        , node "paper-input"
          [ value <| field.value
          , label "value"
          , class [InputField, Value]
          , onInput (UpdateVariableValue id)
          ] []
        ]

    value fieldPart =
      attribute "value" <| Maybe.withDefault "" fieldPart

    label =
      attribute "placeholder"

  in
    div
      [ class [Root]
      ]
      <| List.map renderVariableField (Dict.toList model.variableFields)
