# polyfill promises
promise = require('es6-promise')
if (typeof module isnt 'undefined') and (typeof process isnt 'undefined')
  global.Promise = promise.Promise

Eventric = require './eventric'

module.exports = new Eventric