module UniversalTypes exposing (..)

type alias Variable =
  { name : String
  , value : String
  }

type alias ToastContent =
  { message : String
  , buttonText : String
  , buttonUrl : String
  }
