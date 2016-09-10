module Components.Spinner exposing (view)

import Html exposing (Html, node, text)
import Html.Attributes exposing (attribute, id)
import Html.CssHelpers exposing (withNamespace)

import Styles.Spinner exposing
  ( Classes(Spinner)
  , componentNamespace
  )

{class} =
  withNamespace componentNamespace


-- VIEW

view : String -> List (Html a)
view message =
  let
    spinnerId =
      componentNamespace ++ "spinner"

  in
    [ node "paper-spinner-lite"
      [ id spinnerId
      , attribute "active" ""
      , attribute "name" message
      , class [Spinner]
      ] []
    , node "paper-tooltip"
      [ attribute "for" spinnerId
      , attribute "offset" "20"
      ]
      [ text message
      ]
    ]
