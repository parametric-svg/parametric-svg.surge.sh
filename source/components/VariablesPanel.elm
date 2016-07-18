module VariablesPanel exposing (Model, init)


-- MODEL

type alias Model =
  { variables : List Variable
  }

type alias Variable =
  { name : String
  , rawValue : String
  }

init : Model
init = Model
  [ { name = "a", rawValue = "5" }
  ]
