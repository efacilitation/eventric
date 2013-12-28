describe 'ReadAggregateRoot', ->

  expect = require 'expect'
  ReadAggregateRoot = require('eventric')('ReadAggregateRoot')

  readAggregateRoot = null
  beforeEach ->
    readAggregateRoot = new ReadAggregateRoot