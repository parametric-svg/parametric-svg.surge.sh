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

browser.addCommand('typeIntoEditor', (value) => {
  browser.typeInto(
    elmSelector({
      className: ParametricSvgEditor.Editor,
    }),
    value
  );
});


// CUSTOM ASSERTIONS

const expectDisplaySvgToHaveSize = ({ width, height }) => {
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
};


// STEP DEFINITIONS

module.exports = function stepDefinitions() {
  this.When((
    /^I visit '([^']*)'$/
  ), (path) => {
    browser.url(`http://0.0.0.0:9229${path}`);
  });

  this.When((
    /^I visit '([^']*)' for the first time$/
  ), (path) => {
    browser.url(`http://0.0.0.0:9229${path}`);
    browser.execute(() => {
      localStorage.clear();
    });
    browser.refresh();
  });

  this.When((
    /^I type '([^']*)' into the source panel$/
  ), (source) => {
    browser.typeIntoEditor(source);
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
    const size = browser.getElementSize(
      elmSelector({
        className: ParametricSvgEditor.Display,
      })
    );

    expectDisplaySvgToHaveSize(size);
  });

  this.Then((
    /^the size of the SVG drawing should be '(\d+)' px by '(\d+)' px$/
  ), (width, height) => {
    expectDisplaySvgToHaveSize({ width, height });
  });

  this.When((
    /^I create a blank '(\d+)' by '(\d+)' SVG drawing$/
  ), (width, height) => {
    browser.typeIntoEditor(
      `<svg ${[
        `width="${width}"`,
        `height="${height}"`,
        `viewBox="0 0 ${width} ${height}"`,
      ].join(' ')}></svg>`
    );
  });

  this.Then((
    /^the display should be '(\d+)' px high$/
  ), (height) => {
    const size = browser.getElementSize(
      elmSelector({
        className: ParametricSvgEditor.Display,
      })
    );

    expect(String(size.height)).toBe(height);
  });

  this.Then((
    /^the SVG should be scaled down to fit the '([^']+)' of the display$/
  ), (dimension) => {
    const displaySize = browser.getElementSize(
      elmSelector({
        className: ParametricSvgEditor.Display,
      })
    );

    const svgSize = browser.getElementSize(
      elmSelector({
        className: ParametricSvgEditor.Display,
        suffix: ' svg',
      })
    );

    expect(svgSize[dimension]).toBe(displaySize[dimension]);
  });

  this.Then((
    /^the display should shrink to fit the height of the scaled-down SVG$/
  ), () => {
    const svgSize = browser.getElementSize(
      elmSelector({
        className: ParametricSvgEditor.Display,
        suffix: ' svg',
      })
    );

    const displaySize = browser.getElementSize(
      elmSelector({
        className: ParametricSvgEditor.Display,
      })
    );

    expect(displaySize.height).toBe(svgSize.height);
  });
};
