port module Stylesheets exposing (main)

import Css.File exposing
  ( CssFileStructure
  , compile, toFileStructure
  )
import Html exposing (div)
import Html.App as App
import String

import Styles.ParametricSvgEditor as ParametricSvgEditor
import Styles.VariablesPanel as VariablesPanel
import Styles.Auth as Auth


port files : CssFileStructure -> Cmd msg


type alias CompiledStylesheet =
  { css : String
  , warnings : List String
  }

merge : List CompiledStylesheet -> CompiledStylesheet
merge compiledStylesheets =
  { css = String.join "\n"
    << List.map .css
    <| compiledStylesheets
  , warnings = List.concat
    << List.map .warnings
    <| compiledStylesheets
  }

cssFiles : CssFileStructure
cssFiles =
  toFileStructure [
    ( "styles.css"
    , merge <| List.map compile
      [ ParametricSvgEditor.css
      , VariablesPanel.css
      , Auth.css
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
