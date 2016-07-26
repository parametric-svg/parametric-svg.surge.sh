const elementName = 'github-auth';

const click = (event) => {
  window.open(
    `https://github.com/login/oauth/authorize?${[
      'client_id=04c6b0feda77ed221fdd',
      'scope=gist',
    ].join('&')}`
  );
  // Will redirect to /oauth, which will post a message back here.

  const me = event.currentTarget;
  window.addEventListener('message', (message) => {
    const token = message.data;
    const tokenEvent = new Event('token', {
      detail: { token },
      bubbles: false,
    });
    me.dispatchEvent(tokenEvent);
    me.setAttribute('token', token);
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
