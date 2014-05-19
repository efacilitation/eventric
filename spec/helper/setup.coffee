if typeof window isnt 'undefined'
  root = window
else
  root = global

root.eventric = require 'eventric'
root.sinon    = require 'sinon'
root.mockery  = require 'mockery'
root.chai     = require 'chai'
root.expect   = chai.expect
root.sandbox  = sinon.sandbox.create()