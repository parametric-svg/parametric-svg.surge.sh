import Html.App exposing (beginnerProgram)
import Components.ParametricSvgEditor as ParametricSvgEditor

main : Program Never
main = beginnerProgram
  { model = ParametricSvgEditor.init
  , view = ParametricSvgEditor.view
  , update = ParametricSvgEditor.update
  }
