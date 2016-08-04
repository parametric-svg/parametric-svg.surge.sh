const jssLite = require('jss-lite');

const elementName = 'focus-on-mount';

const prototype = Object.assign(Object.create(HTMLElement.prototype), {
  attachedCallback() {
    setTimeout(() => this.querySelector('[tabindex]').focus());
  },
});

document.registerElement(elementName, { prototype });

const style = document.createElement('style');
style.textContent = jssLite({
  [elementName]: {
    display: 'block',
  },
});
document.head.appendChild(style);
