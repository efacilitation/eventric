require('es6-promise').polyfill()

if typeof window isnt 'undefined'
  root = window
else
  root = global

if not root._spec_setup
  root.sinon    = require 'sinon'
  root.mockery  = require 'mockery'
  root.chai     = require 'chai'
  root.expect   = chai.expect
  root.sandbox  = sinon.sandbox.create()

  sinonChai = require 'sinon-chai'
  chai.use sinonChai
  root._spec_setup = true


root.before ->
  root.eventricStub = sandbox.stub (new (require './eventric'))

  mockery.enable useCleanCache: true
  mockery.warnOnUnregistered false
  mockery.warnOnReplace false


root.beforeEach ->
  root.eventric     = require './'

  #eventric.log.setLogLevel 'debug'

root.afterEach ->
  delete root.eventric
  mockery.resetCache()
  mockery.deregisterAll()
  sandbox.restore()


root.after ->
  mockery.disable()
