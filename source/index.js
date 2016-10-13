require('./custom-elements');
const serializeFileContents = require('./js/serializeFileContents');
const parseFileContents = require('./js/parseFileContents');

const Elm = require('./App.elm');

const app = Elm.Main.embed(
  document.querySelector('#main')
);

const { sendFileContents } = serializeFileContents({
  listener: app.ports.fileContents.send,
});
app.ports.requestFileContents.subscribe(sendFileContents);

const sendGistResponse = (response) => {
  const payload = parseFileContents(response);
  app.ports.receiveParsedFile.send(payload);
};
app.ports.requestParsedFile.subscribe(sendGistResponse);
