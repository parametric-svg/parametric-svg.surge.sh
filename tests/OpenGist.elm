module OpenGist exposing (all)

import Expect
import Fuzz exposing (tuple, tuple3, tuple5, string, map, Fuzzer)
import Test exposing (describe, fuzz, Test)
import Json.Decode exposing (decodeString)
import Regex exposing (replace, regex, HowMany(All))

import Types exposing (GistData)
import Components.OpenGist.Decoders exposing (userGists)




all : Test
all =
  describe "OpenGist"
    [ describe "userGists"


      [ fuzz twoJsonNeutralStrings
        "works for a single file in a single gist"
        <|
        \(id, basename) ->
          """
          [ { "id": \""""++ id ++"""\"
            , "files":
              { \""""++ basename ++""".parametric.svg":
                { "filename": \""""++ basename ++""".parametric.svg"
                }
              }
            }
          ]
          """
            |> decodeString userGists
            |> Expect.equal
              ( Ok [GistData id basename]
              )


      , fuzz threeJsonNeutralStrings
        "works for multiple files in a single gist"
        <|
        \(id, basename1, basename2) ->
          """
          [ { "id": \""""++ id ++"""\"
            , "files":
              { \""""++ basename1 ++""".parametric.svg":
                { "filename": \""""++ basename1 ++""".parametric.svg"
                }
              , \""""++ basename2 ++""".parametric.svg":
                { "filename": \""""++ basename2 ++""".parametric.svg"
                }
              }
            }
          ]
          """
            |> decodeString userGists
            |> Expect.equal
              ( Ok
                [ GistData id basename2
                , GistData id basename1
                ]
              )


      , fuzz fiveJsonNeutralStrings
        "works for multiple gists"
        <|
        \(id1, id2, basename1, basename2, basename3) ->
          """
          [ { "id": \""""++ id1 ++"""\"
            , "files":
              { \""""++ basename1 ++""".parametric.svg":
                { "filename": \""""++ basename1 ++""".parametric.svg"
                }
              , \""""++ basename2 ++""".parametric.svg":
                { "filename": \""""++ basename2 ++""".parametric.svg"
                }
              }
            }
          , { "id": \""""++ id2 ++"""\"
            , "files":
              { \""""++ basename3 ++""".parametric.svg":
                { "filename": \""""++ basename3 ++""".parametric.svg"
                }
              }
            }
          ]
          """
            |> decodeString userGists
            |> Expect.equal
              ( Ok
                [ GistData id1 basename2
                , GistData id1 basename1
                , GistData id2 basename3
                ]
              )


      ]
    ]


twoJsonNeutralStrings : Fuzzer (String, String)
twoJsonNeutralStrings =
  tuple
    ( map ((++) "a") jsonNeutralString
    , map ((++) "b") jsonNeutralString
    )


threeJsonNeutralStrings : Fuzzer (String, String, String)
threeJsonNeutralStrings =
  tuple3
    ( map ((++) "a") jsonNeutralString
    , map ((++) "b") jsonNeutralString
    , map ((++) "c") jsonNeutralString
    )


fiveJsonNeutralStrings : Fuzzer (String, String, String, String, String)
fiveJsonNeutralStrings =
  tuple5
    ( map ((++) "a") jsonNeutralString
    , map ((++) "b") jsonNeutralString
    , map ((++) "c") jsonNeutralString
    , map ((++) "d") jsonNeutralString
    , map ((++) "e") jsonNeutralString
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
