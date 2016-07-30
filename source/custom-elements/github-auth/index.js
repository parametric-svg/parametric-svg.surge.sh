const elementName = 'github-auth';

const click = (event) => {
  window.open(
    `https://github.com/login/oauth/authorize?${[
      'client_id=04c6b0feda77ed221fdd',
      'scope=gist',
    ].join('&')}`
  );
  // Will redirect to /oauth, which will post the auth code back here.

  const element = event.currentTarget;

  window.addEventListener('message', (messageEvent) => {
    const message = messageEvent.data;
    element.dispatchEvent(new CustomEvent('message', {
      detail: message,
      bubbles: false,
    }));
  });
};

const prototype = Object.assign(Object.create(HTMLElement.prototype), {
  attachedCallback() {
    this.addEventListener('click', click);
  },

  detachedCallback() {
    this.removeEventListener('click', click);
  },
});

document.registerElement(elementName, { prototype });
