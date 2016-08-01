require('tap-spec-integrated');
const test = require('tape-catch');
const sinon = require('sinon');
const proxyquire = require('proxyquire');

const { DOMParser, XMLSerializer } = require('xmldom');
/* eslint-disable quote-props */
const prepareFileContents = proxyquire('.', {
  'global': { DOMParser, XMLSerializer },
});
/* eslint-enable quote-props */

const withInput = (
  input
) => ({ expectResult: (
  result
) => (is) => {
  const inPort = sinon.stub();
  const { sendFileContents } = prepareFileContents({ inPort });
  sendFileContents(input);
  is.ok(inPort.calledOnce);
  is.ok(inPort.calledWithExactly(result));
  is.end();
} });

test((
  'Adds <defs>'
), withInput(
  { markup: '<svg></svg>', variables: [{ name: 'a', value: '2' }] }
).expectResult(
  '<svg>' +
    '<defs>' +
      '<param name="a" value="2"/>' +
    '</defs>' +
  '</svg>'
));

test((
  'Adds <defs> at the beginning of the <svg>'
), withInput(
  { markup: '<svg><circle/></svg>', variables: [{ name: 'a', value: '2' }] }
).expectResult(
  '<svg>' +
    '<defs>' +
      '<param name="a" value="2"/>' +
    '</defs>' +
    '<circle/>' +
  '</svg>'
));

test((
  'Adds variables to the end of <defs>'
), withInput({
  markup: '<svg><defs><whatever/></defs></svg>',
  variables: [{ name: 'a', value: '2' }],
}).expectResult(
  '<svg>' +
    '<defs>' +
      '<whatever/>' +
      '<param name="a" value="2"/>' +
    '</defs>' +
  '</svg>'
));
