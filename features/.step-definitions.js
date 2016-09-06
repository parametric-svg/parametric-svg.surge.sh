const { flatten } = require('lodash');


// UTILITY FUNCTIONS

const component = (name, classes) => (
  classes.reduce((result, className) => Object.assign({}, result, {
    [className]: `${name}-${className}`,
  }), {})
);

const elmSelectors = (elmClassName) => [
  `[class$='${elmClassName}']`,
  `[class*='${elmClassName} ']`,
];

const elmClass = (elmClassName) => (
  elmSelectors(elmClassName).join(', ')
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
      elmClass(ParametricSvgEditor.Editor),
      source
    );
  });

  this.When((
    /^I add a variable named '([^']*)' with a value of '([^']*)'$/
  ), (name, value) => {
    const lastInputSelectors = (
      elmSelectors(VariablesPanel.Input)
        .map(selector => `${selector}:last-child`)
    );

    const childOfLastInput = (elmClassName) => {
      const combinations =
        elmSelectors(elmClassName).map(childSelector => (
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
      `${elmClass(ParametricSvgEditor.Display)} svg`
    );

    const expectedMarkup = new RegExp(`<circle\\b[^>]*\\br="${radius}"`);
    browser.waitUntil(() => (
      expectedMarkup.test(markup)
    ), 2000, `'${markup}' should match ${expectedMarkup}`);
  });
};
