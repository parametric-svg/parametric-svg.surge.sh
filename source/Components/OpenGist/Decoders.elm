module Components.OpenGist.Decoders exposing (userGists)

import Json.Decode as Decode exposing
  ( string, keyValuePairs, (:=), list, object2
  , Decoder
  )
import Regex exposing (escape, regex, HowMany(All))
import Exts.Maybe exposing (catMaybes)

import Types exposing (GistData)


userGists : Decoder (List GistData)
userGists =
  let
    gistObject =
      Decode.map toListOfGistData parseGistObject

    toListOfGistData (id, filenames) =
      filenames
        |> List.map (toGistData id)
        |> catMaybes

    toGistData id (_, filename) =
      if Regex.contains parametricSvgFilePattern filename
        then Just <| GistData id (extractBasename filename)
        else Nothing

    extractBasename =
      Regex.replace All parametricSvgFilePattern (always "")

    parametricSvgFilePattern =
      regex <| (escape ".parametric.svg") ++ "$"

    parseGistObject =
      object2 (,)
        ("id" := string)
        ("files" := keyValuePairs ("filename" := string))

  in
    Decode.map List.concat (list gistObject)
