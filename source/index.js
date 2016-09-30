require('./custom-elements');
const serializeFileContents = require('./js/serializeFileContents');

const Elm = require('./App.elm');

const app = Elm.Main.embed(
  document.querySelector('#main')
);

const { sendFileContents } = serializeFileContents({
  listener: app.ports.fileContents.send,
});
app.ports.requestFileContents.subscribe(sendFileContents);
