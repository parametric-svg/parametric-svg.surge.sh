const { flatten } = require('lodash');
const expect = require('expect');


// UTILITY FUNCTIONS

const component = (name, classes) => (
  classes.reduce((result, className) => Object.assign({}, result, {
    [className]: `${name}-${className}`,
  }), {})
);

const elmSelectors = ({
  className,
  suffix = '',
}) => [
  `[class$='${className}']${suffix}`,
  `[class*='${className} ']${suffix}`,
];

const elmSelector = (options) => (
  elmSelectors(options).join(', ')
);

const xmlParameterRegExp = (element, parameterRegExp) => (
  new RegExp(`<${element}\\b[^>]*\\b${parameterRegExp}`)
);


// COMPONENT CLASSES

const ParametricSvgEditor = component('ParametricSvgEditor', [
  'Display',
  'Editor',
]);

const VariablesPanel = component('VariablesPanel', [
  'Input',
  'Parameter',
  'Value',
]);


// CUSTOM COMMANDS

browser.addCommand('typeInto', (selector, value) => {
  browser.doubleClick(selector);
  browser.keys(value);
});


// STEP DEFINITIONS

module.exports = function stepDefinitions() {
  this.When((
    /^I visit '([^']*)'$/
  ), (path) => {
    browser.url(`http://0.0.0.0:9229${path}`);
  });

  this.When((
    /^I type '([^']*)' into the source panel$/
  ), (source) => {
    browser.typeInto(
      elmSelector({
        className: ParametricSvgEditor.Editor,
      }),
      source
    );
  });

  this.When((
    /^I add a variable named '([^']*)' with a value of '([^']*)'$/
  ), (name, value) => {
    const lastInputSelectors = elmSelectors({
      className: VariablesPanel.Input,
      suffix: ':last-child',
    });

    const childOfLastInput = (className) => {
      const combinations =
        elmSelectors({ className }).map(childSelector => (
          lastInputSelectors.map(inputSelector => (
            `${inputSelector} ${childSelector}`
          ))
        ));

      return flatten(combinations).join(', ');
    };

    browser.typeInto(
      childOfLastInput(VariablesPanel.Parameter),
      name
    );
    browser.typeInto(
      childOfLastInput(VariablesPanel.Value),
      value
    );
  });

  this.When((
    /^I stop to see what’s up – TODO: Remove before committing!$/
  ), () => {
    browser.debug();
  });

  this.Then((
    /^I should see a circle with a radius of '([\d]+)' on the canvas$/
  ), (radius) => {
    const markup = browser.getHTML(
      elmSelector({
        className: ParametricSvgEditor.Display,
        suffix: ' svg',
      })
    );

    const expectedMarkup = xmlParameterRegExp('circle', `r="${radius}"`);
    expect(markup).toMatch(expectedMarkup);
  });

  this.Then((
    /^the SVG canvas should be just as large as the display$/
  ), () => {
    const { width, height } = browser.getElementSize(
      elmSelector({
        className: ParametricSvgEditor.Display,
      })
    );

    const svgMarkup = browser.getHTML(
      elmSelector({
        className: ParametricSvgEditor.Display,
        suffix: ' svg',
      })
    );

    expect(svgMarkup).toMatch(
      xmlParameterRegExp('svg', `width="${width}"`)
    );

    expect(svgMarkup).toMatch(
      xmlParameterRegExp('svg', `height="${height}"`)
    );

    expect(svgMarkup).toMatch(
      xmlParameterRegExp('svg', `viewBox="0 0 ${width} ${height}"`)
    );
  });
};
