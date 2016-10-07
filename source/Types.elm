module Types exposing (..)

type alias Context =
  { githubAuthToken : Maybe String
  , drawingId : String
  , variables : List Variable
  , markup : String
  , gistId : Maybe String
  , gistFileSnapshot : Maybe FileSnapshot
  }

type alias Variable =
  { name : String
  , value : String
  }

type alias FileSnapshot =
  { markup : String
  , variables : List Variable
  }

type alias ToastContent =
  { message : String
  , buttonText : String
  , buttonUrl : String
  }
