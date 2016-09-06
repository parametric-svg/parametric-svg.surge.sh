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
  'Textarea',
]);

const VariablesPanel = component('VariablesPanel', [
  'Input',
  'Parameter',
  'Value',
]);


// CUSTOM COMMANDS

browser.addCommand('setValueAttribute', (selector, value) => {
  const callback = ([element], input) => {
    if (element === undefined) throw new Error('No element found!');
    element.setAttribute('value', input);
    element.dispatchEvent(new Event('input'));
  };

  browser.selectorExecute(selector, callback, value);
});

browser.addCommand('setTextareaValue', (selector, value) => {
  const callback = ([element], input) => {
    if (element === undefined) throw new Error('No element found!');
    element.value = input;
    element.dispatchEvent(new Event('input'));
  };

  browser.selectorExecute(selector, callback, value);
});


// STEP DEFINITIONS

module.exports = function stepDefinitions() {
  this.Given((
    /^I visit '([^']*)'$/
  ), (path) => {
    browser.url(`http://0.0.0.0:9229${path}`);
  });

  this.When((
    /^I type '([^']*)' into the source panel$/
  ), (source) => {
    browser.setTextareaValue(
      elmClass(ParametricSvgEditor.Textarea),
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

    browser.setValueAttribute(
      childOfLastInput(VariablesPanel.Parameter),
      name
    );
    browser.setValueAttribute(
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
