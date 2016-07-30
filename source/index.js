require('./custom-elements');

const Elm = require('./Main.elm');

window.github$com_parametricSvg_parametricSvgSurgeSh$app = Elm.Main.embed(
  document.querySelector('#main')
);
