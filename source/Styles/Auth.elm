module Styles.Auth exposing (Classes(..), css, componentNamespace)

import Css.Namespace exposing (namespace)
import Css exposing
  ( Stylesheet
  , stylesheet, (.)
  , property
  )


type Classes
  = ToastLink
  | Spinner

css : Stylesheet
css = stylesheet <| namespace componentNamespace <|
  [ (.) ToastLink
    [ property "color" "inherit"
      -- https://github.com/rtfeldman/elm-css/issues/148
    ]

  , (.) Spinner
    [ property "--paper-spinner-color" "currentColor"
    ]
  ]

componentNamespace : String
componentNamespace =
  "fe43cfb-"
