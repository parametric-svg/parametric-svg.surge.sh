const { DOMParser, XMLSerializer } = require('global');

const parser = new DOMParser();
const serializer = new XMLSerializer();

module.exports = ({ listener }) => {
  const sendFileContents = ({ markup, variables }) => {
    const svg = parser.parseFromString(markup, 'image/svg+xml');
    const existingDefs = svg.getElementsByTagName('defs')[0];
    const hasExistingDefs = !!existingDefs;
    const defs = hasExistingDefs
      ? existingDefs
      : svg.createElement('defs');

    const existingParams = {};
    if (hasExistingDefs) {
      const paramElements = Array.from(defs.getElementsByTagName('param'));
      paramElements.forEach((paramElement) => {
        const name = paramElement.getAttribute('name');
        existingParams[name] = paramElement;
      });
    }

    variables.forEach(({ name, value }) => {
      const existingParam = existingParams[name];
      if (hasExistingDefs && !!existingParam) {
        existingParam.parentNode.removeChild(existingParam);
      }

      const param = svg.createElement('param');
      param.setAttribute('name', name);
      param.setAttribute('value', value);
      defs.appendChild(param);
    });

    if (!hasExistingDefs) {
      const firstChild = svg.documentElement.firstChild;
      svg.documentElement.insertBefore(defs, firstChild);
    }

    const payload = serializer.serializeToString(svg);

    if (/<parsererror\b/.test(payload)) {
      // This seems to be the most portable way to check for a parser error
      // currently. The spec says <parsererror> should have the namespace
      // “http://www.mozilla.org/newlayout/xml/parsererror.xml”, but Chrome
      // renders it with the namespace “http://www.w3.org/1999/xhtml”.

      listener({ payload: null, error: {
        message: (
          'Uh-oh! We can’t serialize the contents of your SVG. Make sure ' +
          'it’s valid XML. If you need help, you can copy the markup ' +
          'and paste it into an online validator.'
        ),
        buttonText: 'Validate your markup',
        buttonUrl: 'https://xmlvalidation.com/',
      } });
    } else {
      listener({ payload, error: null });
    }
  };

  return { sendFileContents };
};
