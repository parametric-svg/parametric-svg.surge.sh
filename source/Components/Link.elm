module Components.Link exposing (link)

import Html exposing (Html, Attribute, a)
import Html.CssHelpers exposing (withNamespace)

import Components.Link.Styles exposing
  ( Classes(Link)
  , componentNamespace
  )

{class} =
  withNamespace componentNamespace


-- VIEW

link : List (Attribute a) -> List (Html a) -> Html a
link attributes =
  a (attributes ++ [class [Link]])
