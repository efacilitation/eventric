if typeof window isnt 'undefined'
  root = window
else
  root = global

if !root._spec_setup
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


beforeEach ->
  root.eventric = require 'eventric'


afterEach ->
  mockery.resetCache()
  mockery.deregisterAll()
  sandbox.restore()


after ->
  mockery.disable()


root._spec_setup = true