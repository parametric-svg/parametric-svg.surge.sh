const component = (name, classes) => (
  classes.reduce((result, className) => Object.assign({}, result, {
    [className]: `${name}-${className}`,
  }), {})
);

const ParametricSvgEditor = component('ParametricSvgEditor', [
  'Display',
  'Textarea',
]);

const elmClass = (elmClassName) => [
  `[class$='${elmClassName}']`,
  `[class*='${elmClassName} ']`,
].join(', ');

module.exports = function stepDefinitions() {
  this.Given((
    /^I visit '([^']*)'$/
  ), (path) => {
    browser.url(`http://0.0.0.0:9229${path}`);
  });

  this.When((
    /^I type '([^']*)' into the source panel$/
  ), (source) => {
    browser.setValue(elmClass(ParametricSvgEditor.Textarea), source);
  });

  this.Then((
    /^I should see a circle with a radius of '([\d]+)' on the canvas$/
  ), (radius) => {
    const markup = browser.getHTML(
      `${elmClass(ParametricSvgEditor.Display)} svg`
    );
    const expected = new RegExp(`<circle\\b[^>]*\\br="${radius}"`);
    if (!expected.test(markup)) throw new Error(
      'Markup doesn’t match'
    );
  });
};
