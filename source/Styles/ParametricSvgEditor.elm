module Styles.ParametricSvgEditor exposing (Classes(..), css, componentNamespace)

import Css.Namespace exposing (namespace)
import Css exposing
  ( Stylesheet
  , stylesheet, (.), selector, children

  , height, width, display, displayFlex, position, backgroundColor, flexGrow
  , minHeight, maxHeight, paddingTop, top, property, marginLeft

  , pct, block, hex, relative, px, int, absolute, zero
  )


type Classes
  = Root
  | Display | Display_ImplicitSize
  | DisplaySizer
  | Editor
  | Toolbar
  | ToolbarButton

css : Stylesheet
css = stylesheet <| namespace componentNamespace <|
  let
    toolbarBackgroundColor =
      hex "8BC34A"
      -- Light Green 500

    codemirrorMaterialBackgroundColor =
      hex "263238"
      -- Blue Grey 900

    white =
      hex "FFFFFF"

  in
    [ (.) Root
      [ height <| pct 100
      , displayFlex
      , backgroundColor codemirrorMaterialBackgroundColor
      ]

    , selector "html"
      [ backgroundColor toolbarBackgroundColor
      ]

    , (.) Toolbar
      [ backgroundColor toolbarBackgroundColor
      , property "--paper-toolbar-title" <| "{ "
        ++ "margin-left: 0; "
        ++ "line-height: 1.5; "
        ++ "}"
      ]

    , (.) ToolbarButton
      [ marginLeft (px 10)
      ]

    , (.) Display
      [ position relative
      , flexGrow (int 1)
      , backgroundColor white
      ]
    , (.) Display [children [selector "parametric-svg > svg"
      [ position absolute
      , top zero
      , width (pct 100)
      , height (pct 100)
      ]]]
    , (.) Display_ImplicitSize
      [ minHeight (pct 60)
      ]

    , (.) DisplaySizer
      [ width (pct 100)
      ]

    , (.) Editor
      [ display block
      , flexGrow (int 1)
      ]
    ]

componentNamespace : String
componentNamespace = "a3e78af-ParametricSvgEditor-"
