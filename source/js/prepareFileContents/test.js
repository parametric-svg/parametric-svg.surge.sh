require('tap-spec-integrated');
const test = require('tape-catch');
const sinon = require('sinon');
const inNode = require('detect-node');
const randomString = require('random-string');

const svgElementMocks = {};
const addElement = ({ drawingId, markup }) => {
  if (inNode) {
    svgElementMocks[drawingId] = markup;
  } else {
    const div = document.createElement('div');
    div.id = drawingId;
    div.innerHTML = markup;
    document.body.appendChild(div);
  }
};

/* eslint-disable quote-props, global-require */
const prepareFileContents = (inNode
  ? (() => {
    const { DOMParser, XMLSerializer } = require('xmldom');
    const proxyquire = require('proxyquire');

    const document = {
      getElementById: (id) => ({
        querySelector: (selector) => {
          if (selector !== 'svg') throw Error('Not implemented');
          return { outerHTML: svgElementMocks[id] };
        },
      }),
    };

    return proxyquire('.', {
      'global': { DOMParser, XMLSerializer, document },
    });
  })()

  : require('.')
);
/* eslint-enable quote-props, global-require */

const withInput = ({
  markup, variables,
}) => {
  const expect = (expectation) => (is) => {
    const listener = sinon.stub();
    const { sendFileContents } = prepareFileContents({ listener });

    const drawingId = randomString();
    addElement({ drawingId, markup });
    sendFileContents({ drawingId, variables });

    is.ok(listener.calledOnce,
      'calls the listener'
    );
    expectation({ is, listener });
    is.end();
  };

  const expectPayload = (result) => expect(({ is, listener }) => {
    is.equal(listener.lastCall.args[0].payload, result,
      'passes the correct `payload`'
    );
    is.equal(listener.lastCall.args[0].error, null,
      'passes no `error`'
    );
  });

  return { expect, expectPayload };
};

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
), withInput({
  markup: '<svg><invalid</svg>',
  variables: [],
}).expect(({ is, listener }) => {
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
}));
