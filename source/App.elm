import Navigation exposing (Parser, program, makeParser)
import Components.ParametricSvgEditor as ParametricSvgEditor exposing
  ( Location, Model, Message(ChangeLocation)
  , init, view, update, subscriptions
  , urlToLocation
  )

main : Program Never
main = program urlParser
  { init = initWithRoute
  , view = view
  , update = update
  , subscriptions = subscriptions
  , urlUpdate = urlUpdate
  }


initWithRoute : Location -> (Model, Cmd Message)
initWithRoute location =
  let
    (initModel, initCommands) =
      init

    (model, updateCommands) =
      update
        (ChangeLocation location)
        initModel

  in
    model
    ! [ initCommands
      , updateCommands
      ]


urlParser : Parser Location
urlParser =
  let
    parseUrl browserLocation =
      urlToLocation browserLocation.pathname

  in
    makeParser parseUrl


urlUpdate : Location -> Model -> (Model, Cmd Message)
urlUpdate location model =
  update
    (ChangeLocation location)
    model
