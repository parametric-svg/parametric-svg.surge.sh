require('tap-spec-integrated');
const test = require('tape-catch');
const sinon = require('sinon');

/* eslint-disable quote-props, global-require */
const inNode = require('detect-node');
const prepareFileContents = (inNode
  ? (() => {
    const { DOMParser, XMLSerializer } = require('xmldom');
    const proxyquire = require('proxyquire');
    return proxyquire('.', {
      'global': { DOMParser, XMLSerializer },
    });
  })()

  : require('.')
);
/* eslint-enable quote-props, global-require */

const withInput = (
  input
) => ({
  expectPayload: (result) => (is) => {
    const listener = sinon.stub();
    const { sendFileContents } = prepareFileContents({ listener });
    sendFileContents(input);
    is.ok(listener.calledOnce,
      'calls the listener'
    );
    is.equal(listener.lastCall.args[0].payload, result,
      'passes the correct `payload`'
    );
    is.equal(listener.lastCall.args[0].error, null,
      'passes no `error`'
    );
    is.end();
  },
});

test((
  'Adds <defs>'
), withInput(
  { markup: '<svg></svg>', variables: [{ name: 'a', value: '2' }] }
).expectPayload(
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
).expectPayload(
  '<svg>' +
    '<defs>' +
      '<param name="a" value="2"/>' +
    '</defs>' +
    '<circle/>' +
  '</svg>'
));

test((
  'Adds variables at the end of existing <defs>'
), withInput({
  markup: '<svg><defs><whatever/></defs></svg>',
  variables: [{ name: 'a', value: '2' }],
}).expectPayload(
  '<svg>' +
    '<defs>' +
      '<whatever/>' +
      '<param name="a" value="2"/>' +
    '</defs>' +
  '</svg>'
));

test((
  'Updates the values of existing variables'
), withInput({
  markup: (
    '<svg>' +
      '<defs>' +
        '<param name="a" value="3"/>' +
        '<param name="b" value="5"/>' +
      '</defs>' +
    '</svg>'
  ),
  variables: [{ name: 'a', value: '2' }],
}).expectPayload(
  '<svg>' +
    '<defs>' +
      '<param name="b" value="5"/>' +
      '<param name="a" value="2"/>' +
    '</defs>' +
  '</svg>'
));

test((
  'Passes an error when given an SVG with invalid contents'
), (is) => {
  const listener = sinon.stub();
  const { sendFileContents } = prepareFileContents({ listener });
  sendFileContents({
    markup: '<svg><invalid</svg>',
    variables: [],
  });

  is.ok(listener.calledOnce,
    'calls the listener'
  );
  is.equal(listener.lastCall.args[0].payload, null,
    'passes no `payload`'
  );
  is.deepEqual(listener.lastCall.args[0].error,
    {
      message: (
        'Uh-oh! We can’t serialize the contents of your SVG. Make sure ' +
        'it’s valid XML. If you need help, you can copy the markup ' +
        'and paste it into an online validator.'
      ),
      buttonText: 'Validate your markup',
      buttonUrl: 'https://xmlvalidation.com/',
    },
    'passes a descriptive `error`'
  );
  is.end();
});
