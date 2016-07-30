module Components.Toast exposing (view)

import Html exposing (Html, node, a, text)
import Html.Attributes exposing (attribute, href, target)
import Html.CssHelpers exposing (withNamespace)

import Styles.Toast exposing
  ( Classes(Link)
  , componentNamespace
  )

{class} =
  withNamespace componentNamespace


-- VIEW

view : String -> Html a
view message =
  node "paper-toast"
    [ attribute "opened" ""
    , attribute "text" message
    ]
    [ a
      [ href "https://github.com/parametric-svg/parametric-svg.surge.sh/issues"
      , target "_blank"
      , class [Link]
      ]
      [ node "paper-button" []
        [ text "Get help"
        ]
      ]
    ]
