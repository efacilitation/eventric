require('es6-promise').polyfill()

if typeof window isnt 'undefined'
  root = window
else
  root = global

if not root._spec_setup
  root.sinon    = require 'sinon'
  root.chai     = require 'chai'
  root.expect   = chai.expect
  root.sandbox  = sinon.sandbox.create()

  sinonChai = require 'sinon-chai'
  chai.use sinonChai
  root._spec_setup = true


beforeEach ->
  root.eventric = require 'eventric'


afterEach ->
  delete root.eventric
  Object.keys(require.cache).forEach (key) ->
    delete require.cache[key]
  sandbox.restore()
