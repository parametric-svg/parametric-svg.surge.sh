const jssLite = require('jss-lite');

module.exports = ({
  name,
  lifecycle,
  isBlock = false,
}) => {
  const prototype = Object.assign(
    Object.create(HTMLElement.prototype),
    lifecycle
  );

  document.registerElement(name, { prototype });

  if (isBlock) {
    const style = document.createElement('style');
    style.textContent = jssLite({
      [name]: {
        display: 'block',
      },
    });
    document.head.appendChild(style);
  }
};
