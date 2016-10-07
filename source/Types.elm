module Types exposing (..)

type alias Context =
  { githubAuthToken : Maybe String
  , drawingId : String
  , variables : List Variable
  , markup : String
  , gistId : Maybe String
  }

type alias Variable =
  { name : String
  , value : String
  }

type alias ToastContent =
  { message : String
  , buttonText : String
  , buttonUrl : String
  }
