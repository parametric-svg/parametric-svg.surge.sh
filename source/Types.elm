module Types exposing (..)

type alias Context =
  { githubAuthToken : Maybe String
  , drawingId : String
  , variables : List Variable
  , markup : String
  , gistState : GistState
  }

type alias Variable =
  { name : String
  , value : String
  }

type GistState
  = NotConnected
  | Uploading FileSnapshot
  | Synced GistData FileSnapshot
  | Downloading GistData

type alias GistData =
  { id : String
  , basename : String
  }

type alias FileSnapshot =
  { markup : String
  , variables : List Variable
  }

type alias ToastContent =
  { message : String
  , buttonText : String
  , buttonUrl : String
  , openInNewTab : Bool
  }
