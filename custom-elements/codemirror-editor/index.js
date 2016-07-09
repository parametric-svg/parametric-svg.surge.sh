/* eslint-disable prefer-template, quote-props */
  // brfs doesn’t play way with template strings ATM
  // jss-lite looks more elegant when all properties are quoted
const codemirror = require('codemirror');
const fs = require('fs');
const jssLite = require('jss-lite');
const privateParts = require('private-parts');

require('codemirror/mode/xml/xml');
require('codemirror/keymap/sublime');

const _ = privateParts.createKey();

const baseCss = fs.readFileSync(
  __dirname + '/../../node_modules/codemirror/lib/codemirror.css', 'utf8'
);
const themeCss = fs.readFileSync(
  __dirname + '/../../node_modules/codemirror/theme/material.css', 'utf8'
);
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
    const shadow = this.createShadowRoot();

    const style = document.createElement('style');
    style.textContent = baseCss + themeCss + styleOverrides;
    shadow.appendChild(style);

    const editor = _(this).editor = codemirror(shadow, {
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

    const content = document.createElement('content');
    shadow.appendChild(content);

    let textarea;
    const updateTextareaValue = () => {
      if (!textarea) return;
      textarea.value = editor.getValue();

      // Dispatch “input” event
      const event = document.createEvent('Events');
      event.initEvent('input', true, true);
      textarea.dispatchEvent(event);
    };
    editor.on('change', updateTextareaValue);

    const rewireTextarea = () => {
      const nextTextarea = Array.from(this.children)
        .find(child => child.tagName === 'TEXTAREA');

      if (nextTextarea !== textarea) {
        textarea = nextTextarea;
        if (textarea === undefined) return;
        nextTextarea.style.display = 'none';
        updateTextareaValue();
      }
    };
    rewireTextarea();
    const observer = new MutationObserver(rewireTextarea);
    observer.observe(this, { childList: true });
  },

  attachedCallback() {
    _(this).editor.focus();
  },
});

document.registerElement('codemirror-editor', { prototype });
