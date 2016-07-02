import Html exposing (node, div, text, Html)
import Html.App exposing (beginnerProgram)
import Html.Attributes exposing (attribute)

main : Program Never
main = beginnerProgram
  { model = ()
  , view = view
  , update = \_ -> \_ -> ()
  }


-- MODEL

type alias Model =
  ()


-- UPDATE

type alias Message =
  ()


-- VIEW

view : Model -> Html Message
view _ =
  node "paper-header-panel"
    [ attribute "mode" "waterfall"
    ]
    [ node "paper-toolbar" []
      [ div []
        [ text "parametric-svg"
        ]
      ]
    , div []
      [ text "(content goes here)"
      ]
    ]
