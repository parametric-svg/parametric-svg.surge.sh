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
  'Returns no variables when there are no <defs>'
), (is) => {
  const { variables } = parseFileContents(
    '<svg>' +
      '<circle r="5"/>' +
    '</svg>'
  );

  is.deepEqual(variables, []);
  is.end();
});

test((
  'Pulls variables out of <defs>'
), (is) => {
  const { variables } = parseFileContents(
    '<svg>' +
      '<defs>' +
        '<param name="width" value="100"/>' +
        '<param name="height" value="200"/>' +
      '</defs>' +
      '<rect parametric:width="width" parametric:height="height"/>' +
    '</svg>'
  );

  is.deepEqual(variables, [
    { name: 'width', value: '100' },
    { name: 'height', value: '200' },
  ]);

  is.end();
});

test((
  'Returns the whole source, pretty printed'
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

  const { source } = parseFileContents(input);

  is.equal(source, [
    '<svg>',
    '  <defs>',
    '    <param name="width" value="100"/>',
    '    <param name="height" value="200"/>',
    '  </defs>',
    '  <rect parametric:width="width" parametric:height="height"/>',
    '</svg>',
  ].join('\n'));

  is.end();
});
