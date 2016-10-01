/* eslint-disable prefer-template */
  // To keep XML markup readable
const test = require('tape-catch');
const inNode = require('detect-node');

/* eslint-disable quote-props, global-require */
const parseFileContents = (inNode ? (() => {
  const DOMParser = require('./test/mocks/DOMParser');
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
  const input = (
    '<svg>' +
      '<circle r="5"/>' +
    '</svg>'
  );

  const { source, variables } = parseFileContents(input);

  is.equal(source, input,
    'returns the correct `source`'
  );
  is.deepEqual(variables, {},
    'returns no variables'
  );
  is.end();
});

test((
  'Pulls variables out of <defs>'
), (is) => {
  const input = (
    '<svg>' +
      '<defs>' +
        '<param name="width" value="100"/>' +
        '<param name="height" value="200"/>' +
      '</defs>' +
      '<rect parametric:width="width" parametric:height="height"/>' +
    '</svg>'
  );

  const { source, variables } = parseFileContents(input);

  is.equal(source, input,
    'returns the correct `source`'
  );

  is.deepEqual(variables, {
    width: '100',
    height: '200',
  }, (
    'returns all variables'
  ));

  is.end();
});
