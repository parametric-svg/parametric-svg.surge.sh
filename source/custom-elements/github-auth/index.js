const elementName = 'github-auth';

const click = (event) => {
  window.open(
    `https://github.com/login/oauth/authorize?${[
      'client_id=5acb6b2bcf82fe08240f',
      'scope=gist',
    ].join('&')}`
  );
  // Will redirect to /oauth.html, which will post the auth code back here.

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
