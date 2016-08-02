require('./custom-elements');
const prepareFileContents = require('./js/prepareFileContents');

const Elm = require('./Main.elm');

const app = Elm.Main.embed(
  document.querySelector('#main')
);

const { sendFileContents } = prepareFileContents({
  listener: app.ports.fileContents.send,
});
app.ports.requestFileContents.subscribe(sendFileContents);
