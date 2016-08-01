const { DOMParser, XMLSerializer } = require('global');

const parser = new DOMParser();
const serializer = new XMLSerializer();

module.exports = ({ inPort }) => {
  const sendFileContents = ({ markup, variables }) => {
    const svg = parser.parseFromString(markup, 'image/svg+xml');
    const defs = svg.createElement('defs');
    variables.forEach(({ name, value }) => {
      const param = svg.createElement('param');
      param.setAttribute('name', name);
      param.setAttribute('value', value);
      defs.appendChild(param);
    });

    const firstChild = svg.documentElement.firstChild;
    svg.documentElement.insertBefore(defs, firstChild);

    inPort(serializer.serializeToString(svg));
  };

  return { sendFileContents };
};
