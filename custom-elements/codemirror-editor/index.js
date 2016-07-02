/* eslint-disable prefer-template */
const codemirror = require('codemirror');
const fs = require('fs');

const codemirrorStyle = fs.readFileSync(
  __dirname + '/../../node_modules/codemirror/lib/codemirror.css', 'utf8'
);

const prototype = Object.assign(Object.create(HTMLElement.prototype), {
  createdCallback() {
    const shadow = this.createShadowRoot();

    const style = document.createElement('style');
    style.textContent = codemirrorStyle;
    shadow.appendChild(style);

    codemirror(shadow);
  },
});

document.registerElement('codemirror-editor', { prototype });
