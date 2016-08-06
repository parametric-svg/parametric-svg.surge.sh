module Components.Toast exposing (custom, basic)

import Html exposing (Html, node, a, text)
import Html.Attributes exposing (attribute, href, target)

import Components.Link exposing (link)


-- VIEW

custom : {message : String, buttonText : String, buttonUrl : String} -> Html a
custom {message, buttonText, buttonUrl} =
  node "paper-toast"
    [ attribute "duration" "10000"
    , attribute "opened" ""
    , attribute "text" message
    ]
    [ link
      [ href buttonUrl
      , target "_blank"
      ]
      [ node "paper-button" []
        [ text buttonText
        ]
      ]
    ]

basic : String -> Html a
basic message =
  custom
    { message = message
    , buttonText = "Get help"
    , buttonUrl =
      "https://github.com/parametric-svg/parametric-svg.surge.sh/issues"
    }
