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

browser.addCommand('elementDisplayed', (selector) => {
  const element = browser.element(selector);
  if (element.type === 'NoSuchElement') return false;
  return !!browser.elementIdDisplayed(element.value.ELEMENT);
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

  this.Then((
    /^I click the '([^']*)' icon button$/
  ), (title) => {
    browser.click(`paper-icon-button[name="${title}"]`);
  });

  this.Then((
    /^a new tab should open$/
  ), () => {
    let tabIds = [];
    browser.waitUntil(() => {
      tabIds = browser.getTabIds();
      return tabIds.length === 2;
    });

    this.newlyOpenedTabId = (tabIds
      .find(tabId => tabId !== browser.getCurrentTabId())
    );
  });

  this.When((
    /^I switch to the newly-opened tab$/
  ), () => {
    expect(this.newlyOpenedTabId).toNotBe(undefined);
    browser.switchTab(this.newlyOpenedTabId);
  });

  this.Then((
    /^the newly-opened tab should close$/
  ), () => {
    let tabIds;
    browser.waitUntil(() => {
      tabIds = browser.getTabIds();
      return (
        tabIds.find(
          tabId => tabId === this.newlyOpenedTabId
        ) === undefined
        &&
        tabIds.length === 1
      );
    });

    this.newlyOpenedTabId = undefined;
    browser.switchTab(tabIds[0]);
  });

  this.Then((
    /^the address bar should contain '([^']*)'$/
  ), (urlPart) => {
    expect(browser.getUrl()).toInclude(urlPart);
  });

  this.When((
    /^I type '([^']*)' into the '([^']*)' input$/
  ), (value, name) => {
    browser.setValue(`input[name="${name}"]`, value);
  });

  this.When((
    /^I click the '([^']*)' button$/
  ), (name) => {
    const buttonSelectors = [
      'input[type=button]',
      'input[type=submit]',
      'button',
    ];
    const selector = (buttonSelectors
      .map(buttonSelector => `${buttonSelector}[name="${name}"]`)
      .join(', ')
    );
    browser.click(selector);
  });

  this.When((
    /^I wait until I see '([^']*)'$/
  ), (text) => {
    browser.waitUntil(() => (
      browser.getText('body').indexOf(text) !== -1
    ));
  });

  this.Then((
    /^eventually I should see a '([^']*)' spinner$/
  ), (name) => {
    browser.waitUntil(() => (
      browser.elementDisplayed(`paper-spinner-lite[name="${name}"]`)
    ));
  });

  this.Then((
    /^I should see a '([^']*)' icon button$/
  ), (name) => {
    expect(
      browser.elementDisplayed(`paper-icon-button[name="${name}"]`)
    ).toBe(true);
  });

  this.Then((
    /^eventually I should see a '([^']*)' icon button$/
  ), (name) => {
    browser.waitUntil(() => (
      browser.elementDisplayed(`paper-icon-button[name="${name}"]`)
    ));
  });
};
