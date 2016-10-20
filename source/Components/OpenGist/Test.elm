import Expect
import Test exposing (test, describe)

import Components.OpenGist exposing (decodeUserGists)




suite : Test
suite =
  describe "decodeUserGists"
    [ test "works for a single file in a single gist" <|
      \() ->
        """
        [
          {
            "id": "327b60fd3db9d21d7155a93c9f5d154d",
            "files": {
              "mptyy.parametric.svg": {
                "filename": "mptyy.parametric.svg",
                "size": 241
              }
            }
          }
        ]
        """
          |> Decode.decodeString decodeUserGists
          |> Expect.equal
            [ { id = "327b60fd3db9d21d7155a93c9f5d154d"
              , basename = "mptyy"
              }
            ]
    ]
