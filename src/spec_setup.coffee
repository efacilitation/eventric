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
  moduleFilenames = Object.keys require.cache
  if window?
    moduleFilenames.forEach (filename) ->
      delete require.cache[filename]
  else
    moduleFilenames.forEach (filename) ->
      isSourceFile = filename.indexOf('src/') > 1
      isEventricPlugin = /node_modules\/eventric-/i.test filename
      if isSourceFile or isEventricPlugin
        delete require.cache[filename]
  sandbox.restore()
