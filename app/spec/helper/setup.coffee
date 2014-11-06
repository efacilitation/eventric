if typeof window isnt 'undefined'
  root = window
else
  root = global

if !root._spec_setup
  root.$ = root.jQuery = require 'jquery'
  require 'angular'
  require 'angular-mocks'
  require 'angular-ui-router'
  require 'bootstrap'

  angular.module 'mock-module', []

  require 'eventric-app/templates'

  root.sinon    = require 'sinon'
  root.mockery  = require 'mockery'
  root.chai     = require 'chai'
  root.expect   = chai.expect
  root.sandbox  = sinon.sandbox.create()

  sinonChai = require 'sinon-chai'
  chai.use sinonChai

  root._spec_setup = true


before ->
  mockery.enable useCleanCache: true
  mockery.warnOnUnregistered false
  mockery.warnOnReplace false


beforeEach ->
  root.eventric = require 'eventric/src'
  mockery.registerMock 'eventric', root.eventric


afterEach ->
  mockery.resetCache()
  mockery.deregisterAll()
  sandbox.restore()


after ->
  mockery.disable()
