const { DOMParser } = require('global');
const parser = new DOMParser();

module.exports = (input) => {
  const inputDoc = parser.parseFromString(input, 'image/svg+xml');
  const params = Array.prototype.slice.call(
    inputDoc.querySelectorAll('defs param')
  );
  const variables = params.reduce((result, param) => {
    const name = param.getAttribute('name');
    const value = param.getAttribute('value');
    return (name && value) ? (
      result.concat([{ name, value }])
    ) : (
      result
    );
  }, []);

  return {
    source: input,
    variables,
  };
};
