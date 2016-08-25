const registerElement = require('../_/registerElement');
const _ = require('private-parts').createKey();

const dispatchSize = (element) => {
  const { width, height } = element.getBoundingClientRect();
  element.dispatchEvent(new CustomEvent('size', {
    detail: { width, height },
    bubbles: false,
  }));
};

registerElement({
  name: 'dimensions-watch',
  isBlock: true,
  lifecycle: {
    attachedCallback() {
      dispatchSize(this);

      _(this).handleWindowResize = () => dispatchSize(this);
      window.addEventListener('resize', _(this).handleWindowResize);
    },

    detachedCallback() {
      window.removeEventListener('resize', _(this).handleWindowResize);
    },
  },
});
