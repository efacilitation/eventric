if typeof window isnt 'undefined'
  root = window
else
  root = global

if !root._spec_setup
  root.eventric = require 'eventric'
  root.sinon    = require 'sinon'
  root.mockery  = require 'mockery'
  root.chai     = require 'chai'
  root.expect   = chai.expect
  root.sandbox  = sinon.sandbox.create()

  sinonChai = require 'sinon-chai'
  chai.use sinonChai


before ->
  mockery.enable useCleanCache: true
  mockery.warnOnUnregistered false
  mockery.warnOnReplace false


afterEach ->
  mockery.resetCache()
  mockery.deregisterAll()
  sandbox.restore()
  require.cache = {}


after ->
  mockery.disable()


root._spec_setup = true