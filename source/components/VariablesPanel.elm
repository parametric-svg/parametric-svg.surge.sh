module VariablesPanel exposing
  ( Model, Variable
  , init, getVariables
  )

import Dict exposing (empty, Dict)


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
