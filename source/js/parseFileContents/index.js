const { DOMParser } = require('global');
const parser = new DOMParser();

module.exports = (input) => {
  const inputDoc = parser.parseFromString(input, 'image/svg+xml');
  const params = Array.prototype.slice.call(
    inputDoc.querySelectorAll('defs param')
  );
  const variables = params.reduce((result, param) => {
    const key = param.getAttribute('name');
    const value = param.getAttribute('value');
    return ((key && value) ? (
      Object.assign({}, result, { [key]: value })
    ) : (
      result
    ));
  }, {});

  return {
    source: input,
    variables,
  };
};
