const registerElement = require('../_/registerElement');

registerElement({
  name: 'submit-on-enter',
  isBlock: true,
  lifecycle: {
    createdCallback() {
      this.addEventListener('keypress', (event) => {
        if (event.key !== 'Enter') return;

        const submitButton = (
          this.querySelector('paper-button[raised]') ||
          this.querySelector('paper-button')
        );
        submitButton.getRipple().simulatedRipple();
        submitButton.fire('tap');
      });
    },
  },
});
