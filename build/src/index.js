var _base;

if (typeof (_base = require('es6-promise')).polyfill === "function") {
  _base.polyfill();
}

module.exports = new (require('./eventric'));
