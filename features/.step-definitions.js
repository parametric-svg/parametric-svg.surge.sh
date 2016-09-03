const expect = require('expect');


// UTILITY FUNCTIONS

const component = (name, classes) => (
  classes.reduce((result, className) => Object.assign({}, result, {
    [className]: `${name}-${className}`,
  }), {})
);

const elmClass = (elmClassName) => [
  `[class$='${elmClassName}']`,
  `[class*='${elmClassName} ']`,
].join(', ');


// COMPONENT CLASSES

const ParametricSvgEditor = component('ParametricSvgEditor', [
  'Display',
  'Textarea',
]);


// CUSTOM COMMANDS

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
    const lastInput = (
      `${elmClass(VariablesPanel.Input)}:last-child`
    );
    browser.setValueAttribute(
      `${lastInput} ${elmClass(VariablesPanel.Parameter)}`,
      name
    );
    browser.setValueAttribute(
      `${lastInput} ${elmClass(VariablesPanel.Value)}`,
      value
    );
  });

  this.Then((
    /^I should see a circle with a radius of '([\d]+)' on the canvas$/
  ), (radius) => {
    const markup = browser.getHTML(
      `${elmClass(ParametricSvgEditor.Display)} svg`
    );

    const expectedMarkup = new RegExp(`<circle\\b[^>]*\\br="${radius}"`);
    expect(markup).toMatch(expectedMarkup);
  });
};
