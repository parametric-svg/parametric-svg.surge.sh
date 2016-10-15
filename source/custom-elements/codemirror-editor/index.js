/* eslint-disable prefer-template, quote-props */
  // brfs doesn’t play well with template strings ATM
  // jss-lite looks more elegant when all properties are quoted
const codemirror = require('codemirror');
const jssLite = require('jss-lite');
const privateParts = require('private-parts');

require('codemirror/mode/xml/xml');
require('codemirror/keymap/sublime');

const $ = privateParts.createKey();

const baseCss = require('codemirror/lib/codemirror.css');
const themeCss = require('codemirror/theme/material.css');
const styleOverrides = jssLite({
  '.CodeMirror': {
    'font-family': '"source code pro", monospace',
    'height': 'auto',
    'padding': '0.5em',
    'cursor': 'text',
  },
});


const prototype = Object.assign(Object.create(HTMLElement.prototype), {
  createdCallback() {
    // Apply styles
    const style = document.createElement('style');
    style.textContent = baseCss + themeCss + styleOverrides;
    this.appendChild(style);

    // Configure editor
    const editor = $(this).editor = codemirror(this, {
      mode: 'xml',
      theme: 'material',
      keyMap: 'sublime',
      tabSize: 2,
      inputStyle: 'contenteditable',
      autofocus: true,
      smartIndent: false,
      scrollbarStyle: null,
      lineWrapping: true,
    });
    editor.setOption('extraKeys', {
      Tab: (cm) => {
        cm.replaceSelection('  ', 'end');
      },
    });

    // `value` attribute
    this.setAttribute('value', '');

    // `value` property
    let valueSnapshot = '';
    Object.defineProperty(this, 'value', {
      __proto__: null,
      enumerable: true,

      get: () => (
        editor.getValue()
      ),

      set: (value) => {
        if (value !== valueSnapshot) {
          editor.setValue(value);
        }

        // `value` attribute
        this.setAttribute('value', value);

        // `input` event
        const event = document.createEvent('Events');
        event.initEvent('input', true, true);
        this.dispatchEvent(event);
      },
    });

    editor.on('change', () => {
      // `value` property
      const value = editor.getValue();
      valueSnapshot = value;
      this.value = value;
    });
  },

  attachedCallback() {
    $(this).editor.focus();
  },

  attributeChangedCallback(attribute, _, newValue) {
    switch (attribute) {
      // `value` attribute
      case 'value':
        this.value = newValue;
        return;

      default:
        return;
    }
  },
});

document.registerElement('codemirror-editor', { prototype });
