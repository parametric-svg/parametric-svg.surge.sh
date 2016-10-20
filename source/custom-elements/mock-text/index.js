const registerElement = require('../_/registerElement');
const inline = require('strip-newlines');
const random = require('lodash.random');

registerElement({
  name: 'mock-text',

  lifecycle: {
    createdCallback() {
      const mockText = document.createElement('div');
      mockText.style = inline`
        display: inline-block;
        vertical-align: baseline;
        height: 1ex;
        background-color: currentColor;
        opacity: 0.3;
        border-radius: 0.5ex;
        width: ${random(15, 30)}ch;
        max-width: 100%;
      `;
      this.appendChild(mockText);

      this.appendChild(document.createTextNode(
        '\u00A0'  // no-break space
      ));
    },
  },
});
