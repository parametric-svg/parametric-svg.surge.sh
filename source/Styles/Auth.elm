module Styles.Auth exposing (Classes(..), css, componentNamespace)

import Css.Namespace exposing (namespace)
import Css exposing
  ( Stylesheet
  , stylesheet, (.)
  , property
  )


type Classes
  = Spinner

css : Stylesheet
css = stylesheet <| namespace componentNamespace <|
  [ (.) Spinner
    [ property "--paper-spinner-color" "currentColor"
    ]
  ]

componentNamespace : String
componentNamespace =
  "fe43cfb-Auth-"
