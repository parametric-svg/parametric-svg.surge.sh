port module Stylesheets exposing (main)

import Css.File exposing
  ( CssFileStructure
  , compile, toFileStructure
  )
import Html exposing (div)
import Html.App as App
import String

import Components.ParametricSvgEditor.Styles as ParametricSvgEditor
import Components.VariablesPanel.Styles as VariablesPanel
import Components.Link.Styles as Link
import Components.Spinner.Styles as Spinner


port files : CssFileStructure -> Cmd msg


type alias CompiledStylesheet =
  { css : String
  , warnings : List String
  }

merge : List CompiledStylesheet -> CompiledStylesheet
merge compiledStylesheets =
  { css = compiledStylesheets
    |> List.map .css
    |> String.join "\n"
  , warnings = compiledStylesheets
    |> List.map .warnings
    |> List.concat
  }

cssFiles : CssFileStructure
cssFiles =
  toFileStructure [
    ( "styles.css"
    , merge <| List.map compile
      [ ParametricSvgEditor.css
      , VariablesPanel.css
      , Link.css
      , Spinner.css
      ]
    )]


main : Program Never
main =
  App.program
    { init = ( (), files cssFiles )
    , view = \_ -> (div [] [])
    , update = \_ _ -> ( (), Cmd.none )
    , subscriptions = \_ -> Sub.none
    }
