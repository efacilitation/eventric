describe 'ReadAggregateRoot', ->

  expect            = require 'expect'
  eventric          = require 'eventric'
  ReadAggregateRoot = eventric 'ReadAggregateRoot'

  readAggregateRoot = null
  beforeEach ->
    readAggregateRoot = new ReadAggregateRoot