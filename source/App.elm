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
  update
    (ChangeLocation location)
    (fst init)


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
