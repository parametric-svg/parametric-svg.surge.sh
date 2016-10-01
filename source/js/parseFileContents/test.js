/* eslint-disable prefer-template */
  // To keep XML markup readable
const test = require('tape-catch');
const inNode = require('detect-node');
const sinon = require('sinon');

/* eslint-disable quote-props, global-require */
const querySelectorAll = sinon.stub().returns({ length: 0 });
const parseFromString = sinon.stub().returns({ querySelectorAll });
const parseFileContents = (inNode ? (() => {
  const DOMParser = function DOMParser() { return { parseFromString }; };
  const proxyquire = require('proxyquire');
  return proxyquire('.', {
    'global': { DOMParser },
  });
})() : (
  require('.')
));
/* eslint-enable quote-props, global-require */

test((
  'Returns the raw SVG and no variables when there are no <defs>'
), (is) => {
  const { callCount } = parseFromString;
  const input = (
    '<svg>' +
      '<circle r="5"/>' +
    '</svg>'
  );
  querySelectorAll.returns({ length: 0 });

  const { source, variables } = parseFileContents(input);

  is.deepEqual(
    [parseFromString.callCount, parseFromString.lastCall.args],
    [callCount + 1, [input, 'image/svg+xml']],
    'parses the input as SVG'
  );
  is.equal(source, input,
    'returns the correct `source`'
  );
  is.deepEqual(variables, {},
    'returns no variables'
  );
  is.end();
});
