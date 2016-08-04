const registerElement = require('../_/registerElement');

registerElement({
  name: 'focus-on-mount',
  isBlock: true,
  lifecycle: {
    attachedCallback() {
      setTimeout(() => this.querySelector('[tabindex]').focus());
    },
  },
});
