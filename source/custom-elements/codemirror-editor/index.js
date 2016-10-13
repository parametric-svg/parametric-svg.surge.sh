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


// TODO TODO TODO!!!!
// Ditch the textarea crap, wire things up with pure attributes.
const prototype = Object.assign(Object.create(HTMLElement.prototype), {
  createdCallback() {
    const shadow = this.createShadowRoot();

    const style = document.createElement('style');
    style.textContent = baseCss + themeCss + styleOverrides;
    shadow.appendChild(style);

    const editor = $(this).editor = codemirror(shadow, {
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

    const updateEditorValue = (event) => {
      if (event.target.value === editor.getValue()) return;
      editor.setValue(event.target.value);
    };

    const rewireTextarea = () => {
      const nextTextarea = Array.from(this.children)
        .find(child => child.tagName === 'TEXTAREA');

      if (nextTextarea !== textarea) {
        if (textarea !== undefined) {
          textarea.removeEventListener('input', updateEditorValue);
        }

        textarea = nextTextarea;
        if (textarea === undefined) return;

        textarea.style.display = 'none';
        updateTextareaValue();
        textarea.addEventListener('input', updateEditorValue);
      }
    };
    rewireTextarea();

    // Always keep the first <textarea> wired up
    const observer = new MutationObserver(rewireTextarea);
    observer.observe(this, { childList: true });
  },

  attachedCallback() {
    $(this).editor.focus();
  },

  attributeChangedCallback(attribute, _, newValue) {
    if (attribute !== 'value') return;
    if ($(this).editor.getValue() === newValue) return;
    $(this).editor.setValue(newValue);
  }
});

document.registerElement('codemirror-editor', { prototype });
