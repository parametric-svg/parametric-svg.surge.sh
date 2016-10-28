module Components.OpenGist.Decoders exposing (userGists)

import Json.Decode as Decode exposing
  ( string, keyValuePairs, (:=), list, object2
  , Decoder
  )
import Regex exposing (replace, escape, regex, HowMany(All))

import Types exposing (GistData)


userGists : Decoder (List GistData)
userGists =
  let
    gistObject =
      Decode.map toListOfGistData parseGistObject

    toListOfGistData (id, filenames) =
      List.map (toGistData id) filenames

    toGistData id (_, filename) =
      GistData id (extractBasename filename)

    extractBasename =
      replace All
        (regex <| (escape ".parametric.svg") ++ "$")
        (always "")

    parseGistObject =
      object2 (,)
        ("id" := string)
        ("files" := keyValuePairs ("filename" := string))

  in
    Decode.map List.concat (list gistObject)
