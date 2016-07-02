import Html exposing (h1, text, Html)
import Html.App exposing (beginnerProgram)

main : Program Never
main = beginnerProgram
  { model = ()
  , view = \_ -> h1 [] [text "Hello world!"]
  , update = \_ -> \_ -> ()
  }
