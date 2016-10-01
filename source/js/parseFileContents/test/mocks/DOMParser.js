const invariant = require('invariant');
const { flatten } = require('lodash');

const parseFromString = (source, mimeType) => {
  invariant(mimeType === 'image/svg+xml', 'only image/svg+xml supported');

  const querySelectorAll = (selector) => {
    invariant(selector === 'defs param', 'only `defs param` supported');

    const defsStrings = source.match(/<defs>.*<\/defs>/g) || [];
    const paramStrings = flatten(defsStrings.map(
      defs => (defs.match(/<param\b.*?\/>/g) || [])
    ));

    const params = paramStrings.map((param) => {
      const attributes = ['name', 'value'].map(key => {
        const match = param.match(new RegExp(`\\b${key}="(.*?)"`));
        const value = match ? match[1] : null;
        return { key, value };
      });

      const getAttribute = (attribute) => (
        attributes.find(({ key }) => key === attribute) ||
        { value: null }
      ).value;

      return { getAttribute };
    });

    return params;
  };

  return { querySelectorAll };
};

module.exports = function DOMParser() {
  return { parseFromString };
};
