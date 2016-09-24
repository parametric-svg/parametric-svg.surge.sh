const { flatten } = require('lodash');
const expect = require('expect');
const fetch = require('node-fetch');


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

const nameSelector = (name, baseSelectors) => (
  baseSelectors
  .map(selector => `${selector}[name="${name}"]`)
  .join(', ')
);
const input = (name) => nameSelector(name, [
  'input',
  'paper-input',
]);
const iconButton = name => nameSelector(name, [
  'paper-icon-button',
]);
const spinner = name => nameSelector(name, [
  'paper-spinner-lite',
]);

const elementId = element => element.value.ELEMENT;


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
  // Triple click and type
  browser.click(selector);
  browser.click(selector);
  browser.click(selector);
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
  return !!browser.elementIdDisplayed(elementId(element));
});

browser.addCommand('elementId', (selector) => (
  elementId(browser.element(selector))
));


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
  ), (name) => {
    browser.click(iconButton(name));
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
    browser.typeInto(input(name), value);
  });

  this.Then((
    /^I should see an? '([^']*)' input$/
  ), (name) => {
    expect(
      browser.elementDisplayed(input(name))
    ).toBe(true);
  });

  this.When((
    /^I click the '([^']*)' button$/
  ), (name) => {
    const button = nameSelector(name, [
      'input[type=button]',
      'input[type=submit]',
      'button',
      'paper-button',
    ]);
    browser.click(button);
  });

  this.When((
    /^I wait until I see '([^']*)'$/
  ), (text) => {
    browser.waitUntil(() => (
      browser.getText('body').indexOf(text) !== -1
    ));
  });

  this.Then((
    /^I should see an? '([^']*)' spinner$/
  ), (name) => {
    expect(
      browser.elementDisplayed(spinner(name))
    ).toBe(true);
  });

  this.Then((
    /^eventually I should see an? '([^']*)' spinner$/
  ), (name) => {
    browser.waitUntil(() => browser.elementDisplayed(
      spinner(name)
    ));
  });

  this.Then((
    /^I should see an? '([^']*)' icon button$/
  ), (name) => {
    expect(
      browser.elementDisplayed(iconButton(name))
    ).toBe(true);
    this.lastSeenIconButtonId = browser.elementId(iconButton(name));
  });

  this.Then((
    /^eventually I should see an? '([^']*)' icon button$/
  ), (name) => {
    browser.waitUntil(() => browser.elementDisplayed(
      iconButton(name)
    ));
    this.lastSeenIconButtonId = browser.elementId(iconButton(name));
  });

  this.Then((
    /^the icon button should be a link to '([^']*)' opening in a new tab$/
  ), (urlStartPattern) => {
    const urlStart = urlStartPattern.replace(/<.*$/, '');
    const link = browser.element(`a[target="_blank"][href^="${urlStart}"]`);

    const urlPattern = new RegExp(
      `^${urlStartPattern.replace(/<gist id>$/, '(.*)')}$`
    );
    const url = link.getAttribute('href');
    this.lastGistId = url.match(urlPattern)[1];

    const iconButtonElement = (
      browser.elementIdElement(elementId(link), 'paper-icon-button')
    );
    expect(
      elementId(iconButtonElement)
    ).toBe(
      this.lastSeenIconButtonId
    );
  });

  this.When((
    /^I look at the gist under that id$/
  ), () => {
    expect(this.lastGistId).toBeA('string');
    return fetch(
      `https://api.github.com/gists/${this.lastGistId}`
    ).then(
      response => response.json()
    ).then(data => {
      this.gistData = data;
    });
  });

  this.Then((
    /^there should be one file inside$/
  ), () => {
    const filenames = Object.keys(this.gistData.files);
    expect(filenames.length).toBe(1);
    this.lastFile = {
      name: filenames[0],
      content: this.gistData.files[filenames[0]].content,
    };
  });

  this.Then((
    /^the file should be named '([^']*)'$/
  ), (filename) => {
    expect(this.lastFile.name).toBe(filename);
  });

  this.Then((
    /^the file should contain '([^']*)'$/
  ), (snippet) => {
    expect(this.lastFile.content).toContain(snippet);
  });

  this.Then((
    /^the file should contain the attribute '([^']*)' on the SVG tag$/
  ), (attribute) => {
    expect(this.lastFile.content).toMatch(new RegExp(
      `<svg\\b[^>]*\\b${attribute}`
    ));
  });
};
