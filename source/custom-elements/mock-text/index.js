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
        opacity: 0.5;
        border-radius: 0.5ex;
        width: ${random(20, 40)}ch;
      `;
      this.appendChild(mockText);

      this.appendChild(document.createTextNode(
        '\u00A0'  // no-break space
      ));
    },
  },
});
