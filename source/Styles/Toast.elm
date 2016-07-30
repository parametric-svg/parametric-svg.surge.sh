module Styles.Toast exposing (Classes(..), css, componentNamespace)

import Css.Namespace exposing (namespace)
import Css exposing
  ( Stylesheet
  , stylesheet, (.)
  , property
  )


type Classes = Link

css : Stylesheet
css = (stylesheet << namespace componentNamespace) <|
  [ (.) Link
    [ property "color" "inherit"
      -- https://github.com/rtfeldman/elm-css/issues/148
    ]
  ]

componentNamespace : String
componentNamespace = "b4ea81c-Toast-"
