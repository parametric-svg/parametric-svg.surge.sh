module VariablesPanel exposing
  ( Model, Variable, Message
  , init, getVariables, update, view, css
  )

import Css.Namespace exposing (namespace)
import Css exposing
  ( Stylesheet
  , stylesheet, (.), after

  , backgroundColor, color, property, padding3, displayFlex, flexDirection
  , width, flexGrow, position, content, bottom

  , hex, em, row, int, right, relative, absolute, zero
  )
import Dict exposing (empty, Dict)
import Html exposing (div, node, Html)
import Html.Attributes exposing (attribute)
import Html.Events exposing (onInput)
import Html.CssHelpers exposing (withNamespace)

{class} =
  withNamespace componentNamespace


-- MODEL

type alias Model =
  { variableFields : Dict Id VariableField
  , nextId : Id
  }

type alias VariableField =
  { name : Maybe String
  , rawValue : Maybe String
  }

type alias Variable =
  { name : String
  , rawValue : String
  }

type alias Id =
  Int

init : Model
init =
  Model
    (Dict.fromList [emptyVariableField 0])
    1

getVariables : Model -> List Variable
getVariables { variableFields } =
  let
    toVariable field =
      case (field.name, field.rawValue) of
        (Just name, Just rawValue) ->
          Just {name = name, rawValue = rawValue}
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
      {variable | rawValue =
        if value == ""
          then Nothing
          else Just value
      }

    normalizeVariableFields fields =
      Dict.fromList
      <| List.filter notEmpty (Dict.toList fields)
      ++ [emptyVariableField model.nextId]

    notEmpty (_, fieldData) =
      if fieldData == {name = Nothing, rawValue = Nothing}
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
          [ value <| field.rawValue
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


-- STYLES

type Classes = Root | Input | InputField | Parameter | Value

css : Stylesheet
css = (stylesheet << namespace componentNamespace) <|
  let
    panelBackgroundColor =
      "607D8B"
      -- Blue Grey 500

    secondaryColor =
      "B0BEC5"
      -- Blue Grey 200

    highlightColor =
      "8BC34A"
      -- Light Green 500

    white =
      "FFFFFF"

  in
    [ (.) Root
      [ padding3 zero (em 1) (em 1)
      , backgroundColor (hex panelBackgroundColor)
      , color (hex white)
      ]

    , (.) Input
      [ displayFlex
      , flexDirection row
      ]

    , (.) InputField
      [ property "--paper-input-container-color" ("#" ++ secondaryColor)
      , property "--paper-input-container-focus-color" ("#" ++ highlightColor)
      , property "--paper-input-container-input-color" ("#" ++ white)
      ]
    , (.) Parameter
      [ width (em 7)
      , position relative
      , after
        [ position absolute
        , color (hex white)
        , property "content" "'='"
        , right (em 0.95)
        , bottom (em 0.65)
        ]
      ]
    , (.) Value
      [ flexGrow (int 1)
      ]
    ]

componentNamespace : String
componentNamespace = "b7sj97j-VariablesPanel-"
