module Components.OpenGist.Decoders exposing (userGists)

import Json.Decode exposing (..)
  -- ( string, object2, andThen
  -- , Decoder
  -- )
import Regex exposing (replace, escape, regex, HowMany(All))

import Types exposing (GistData)


-- userGists : Decoder (List GistData)
userGists =
  -- let
  --   gistFile =
  --     object2 GistData
  --       ("id" := string)
  --       ("files" := filename)
  --
  --   filename =
  let
    gistFiles =
      map extractBasenames rawFilenames

    extractBasenames =
      List.map
        ( snd
        >> replace
          All
          (regex <| (escape ".parametric.svg") ++ "$")
          (always "")
        )

    rawFilenames =
      "files" := keyValuePairs ("filename" := string)

  in
    list gistFiles
