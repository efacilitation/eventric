require('es6-promise').polyfill()

root = if window? then window else global

root.sinon    = require 'sinon'
root.chai     = require 'chai'
root.expect   = chai.expect
root.sandbox  = sinon.sandbox.create()

sinonChai = require 'sinon-chai'
chai.use sinonChai


beforeEach ->
  root.eventric = require 'eventric'


afterEach ->
  # TODO: Implement proper destroy() functionality on eventric so this cleanup can be removed
  moduleFilenames = Object.keys require.cache
  areSpecsRunningInBrowser = window?
  if areSpecsRunningInBrowser
    moduleFilenames.forEach (filename) ->
      delete require.cache[filename]
  else
    moduleFilenames.forEach (filename) ->
      isSourceFile = filename.indexOf('src/') > 1
      isEventricPlugin = /node_modules\/eventric-/i.test filename
      if isSourceFile or isEventricPlugin
        delete require.cache[filename]
  sandbox.restore()
