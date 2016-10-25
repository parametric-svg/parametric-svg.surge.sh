module OpenGist exposing (all)

import Expect
import Test exposing (test, describe, Test)
import Json.Decode exposing (decodeString)

import Components.OpenGist.Decoders exposing (userGists)




all : Test
all =
  describe "OpenGist"
    [ describe "userGists"
      -- [ test "works for a single file in a single gist" <|
      --   \() ->
      --     """
      --     [
      --       {
      --         "id": "327b60fd3db9d21d7155a93c9f5d154d",
      --         "files": {
      --           "mptyy.parametric.svg": {
      --             "filename": "mptyy.parametric.svg"
      --           }
      --         }
      --       }
      --     ]
      --     """
      --       |> decodeString userGists
      --       |> Expect.equal
      --         ( Ok
      --           [ { id = "327b60fd3db9d21d7155a93c9f5d154d"
      --             , basename = "mptyy"
      --             }
      --           ]
      --         )

      [ test "temp" <|
        \() ->
          """
          [
            {
              "id": "327b60fd3db9d21d7155a93c9f5d154d",
              "files": {
                "a.parametric.svg": {
                  "filename": "a.parametric.svg"
                },
                "b.parametric.svg": {
                  "filename": "b.parametric.svg"
                }
              }
            }
          ]
          """
            |> decodeString userGists
            |> Expect.equal
              (Ok [["b", "a"]])

      ]
    ]
