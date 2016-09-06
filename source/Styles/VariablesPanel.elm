module Styles.VariablesPanel exposing (Classes(..), css, componentNamespace)

import Css.Namespace exposing (namespace)
import Css exposing
  ( Stylesheet
  , stylesheet, (.), after, mediaQuery

  , backgroundColor, color, property, padding3, displayFlex, flexDirection
  , width, flexGrow, position, content, bottom, borderRight3, flexWrap
  , paddingLeft

  , hex, em, row, int, right, relative, absolute, zero, solid, wrap, pct
  )


type Classes = Root | Input | InputField | Parameter | Value

css : Stylesheet
css = stylesheet <| namespace componentNamespace <|
  let
    panelBackgroundColor =
      "C5E1A5"
      -- Light Green 200

    secondaryColor =
      "90A4AE"
      -- Blue Grey 300

    highlightColor =
      "558B2F"
      -- Light Green 800

    inputColor =
      "263238"
      -- Blue Grey 900

    minFieldWidthEm =
      20

    largestSupportedScreenWidthEm =
      4 * 1024 / 16

    widthDenominators =
      let
        largestDenominator =
          ceiling (largestSupportedScreenWidthEm / minFieldWidthEm)
      in
        [1..largestDenominator]

    fieldSpacing =
      em 1.5

  in
    [ (.) Root
      [ padding3 zero zero (em 1.5)
      , backgroundColor (hex panelBackgroundColor)
      , color (hex inputColor)
      , borderRight3 fieldSpacing solid (hex panelBackgroundColor)
      , displayFlex
      , flexWrap wrap
      ]

    , (.) Input
      [ displayFlex
      , width (pct 100)
      , paddingLeft fieldSpacing
      ]
    ] ++
    List.map (\denominator -> mediaQuery (
      "all and (min-width: "
      ++ toString (denominator * minFieldWidthEm)
      ++ "em)"
    ) [(.) Input
      [ width <| pct <| 100 / toFloat denominator
      ]]
    ) widthDenominators ++

    [ (.) InputField
      [ property "--paper-input-container-color" ("#" ++ secondaryColor)
      , property "--paper-input-container-focus-color" ("#" ++ highlightColor)
      , property "--paper-input-container-input-color" ("#" ++ inputColor)
      ]
    , (.) Parameter
      [ width (em 7)
      , position relative
      , after
        [ position absolute
        , color (hex inputColor)
        , property "content" "'='"
        , right (em 0.95)
        , bottom (em 0.65)
        ]
      ]
    , (.) Value
      [ flexGrow (int 1)
      ]
    ]

componentNamespace : String
componentNamespace = "b7sj97j-VariablesPanel-"
