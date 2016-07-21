module VariablesPanel exposing
  ( Model, Variable, Message
  , init, getVariables, view, css
  )

import Css.Namespace exposing (namespace)
import Css exposing
  ( Stylesheet
  , stylesheet, (.)
  , backgroundColor, color
  , hex
  )
import Dict exposing (empty, Dict)
import Html exposing (div, node, Html)
import Html.Attributes exposing (attribute)
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
  Model empty 0

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


-- ACTIONS

type Message
  = UpdateVariableName Id String
  | UpdateVariableValue Id String


-- VIEW

view : Model -> Html Message
view model =
  let
    renderVariableField field =
      div []
        [ node "paper-input"
          [ value field.name
          , placeholder "parameter"
          , class [Input]
          ] []
        , node "paper-input"
          [ value field.rawValue
          , placeholder "value"
          , class [Input]
          ] []
        ]

    value fieldPart =
      attribute "value" <| Maybe.withDefault "" fieldPart

    placeholder =
      attribute "placeholder"

    newVariableField =
      renderVariableField {name = Nothing, rawValue = Nothing}

  in
    div
      [ class [Root]
      ]
      <| List.map renderVariableField (Dict.values model.variableFields)
      ++ [newVariableField]


-- STYLES

type Classes = Root | Input

css : Stylesheet
css = (stylesheet << namespace componentNamespace) <|
  let
    panelBackgroundColor =
      hex "607D8B"
      -- Blue Grey 500

    white =
      hex "FFFFFF"

  in
    [ (.) Root
      [ backgroundColor panelBackgroundColor
      , color white
      ]
    ]

componentNamespace : String
componentNamespace = "b7sj97j-VariablesPanel-"
