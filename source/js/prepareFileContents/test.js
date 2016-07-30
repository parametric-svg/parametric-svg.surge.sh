require('tap-spec-integrated');
const test = require('tape-catch');
const sinon = require('sinon');

const prepareFileContents = require('.');

test('Works as expected', (is) => {
  const inPort = sinon.stub();
  const { sendFileContents } = prepareFileContents({ inPort });

  sendFileContents('<svg></svg>', [{ name: 'a', value: '2' }]);

  is.ok(inPort.calledOnce);
  is.ok(inPort.calledWithExactly(
    '<svg>' +
      '<defs>' +
        '<param name="a" value="2" />' +
      '</defs>' +
    '</svg>'
  ));

  is.end();
});
