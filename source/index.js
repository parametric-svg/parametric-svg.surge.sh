require('./custom-elements');

const Elm = require('./Main.elm');

Elm.Main.embed(
  document.querySelector('#main')
);
