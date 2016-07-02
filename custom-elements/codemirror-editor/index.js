/* eslint-disable prefer-template */
const codemirror = require('codemirror');
const fs = require('fs');
const jssLite = require('jss-lite');

require('codemirror/mode/xml/xml');

const baseCss = fs.readFileSync(
  __dirname + '/../../node_modules/codemirror/lib/codemirror.css', 'utf8'
);
const themeCss = fs.readFileSync(
  __dirname + '/../../node_modules/codemirror/theme/material.css', 'utf8'
);
const styleOverrides = jssLite({
  '.CodeMirror': {
    'font-family': '"source code pro", monospace',
  },
});

const prototype = Object.assign(Object.create(HTMLElement.prototype), {
  createdCallback() {
    const shadow = this.createShadowRoot();

    const style = document.createElement('style');
    style.textContent = baseCss + themeCss + styleOverrides;
    shadow.appendChild(style);

    const editor = codemirror(shadow, {
      mode: 'xml',
      theme: 'material',
      tabSize: 2,
      inputStyle: 'contenteditable',
      autofocus: true,
    });
    editor.setOption('extraKeys', {
      Tab: (cm) => {
        cm.replaceSelection('  ', 'end');
      },
    });
  },
});

document.registerElement('codemirror-editor', { prototype });
