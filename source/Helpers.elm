module Helpers exposing ((!!))

(!!) : (a, b) -> c -> (a, b, c)
(!!) (model, command) messageToParent =
  (model, command, messageToParent)
