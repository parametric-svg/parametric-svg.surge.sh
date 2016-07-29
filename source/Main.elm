import Html.App exposing (program)
import Components.ParametricSvgEditor as ParametricSvgEditor

main : Program Never
main = program
  { init = ParametricSvgEditor.init
  , view = ParametricSvgEditor.view
  , update = ParametricSvgEditor.update
  , subscriptions = ParametricSvgEditor.subscriptions
  }
