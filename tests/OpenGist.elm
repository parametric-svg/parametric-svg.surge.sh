module OpenGist exposing (all)

import Expect
import Fuzz exposing (tuple3, string, map, Fuzzer)
import Test exposing (describe, fuzz, Test)
import Json.Decode exposing (decodeString)
import Regex exposing (replace, regex, HowMany(All))

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

      [ fuzz threeJsonNeutralStrings
        "works for multiple files in a single gist"
        <|
        \(id, basename1, basename2) ->
          """
          [
            {
              "id": \""""++ id ++"""\",
              "files": {
                \""""++ basename1 ++""".parametric.svg": {
                  "filename": \""""++ basename1 ++""".parametric.svg"
                },
                \""""++ basename2 ++""".parametric.svg": {
                  "filename": \""""++ basename2 ++""".parametric.svg"
                }
              }
            }
          ]
          """
            |> decodeString userGists
            |> Expect.equal
              (Ok [[basename2, basename1]])

      ]
    ]


threeJsonNeutralStrings : Fuzzer (String, String, String)
threeJsonNeutralStrings =
  tuple3
    ( map ((++) "a") jsonNeutralString
    , map ((++) "b") jsonNeutralString
    , map ((++) "c") jsonNeutralString
    )


jsonNeutralString : Fuzzer String
jsonNeutralString =
  string
    |> map
      ( replace
        All
        (regex "[\\\\\"\n]")
        (always "_")
      )
