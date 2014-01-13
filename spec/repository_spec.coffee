describe 'Repository', ->

  sinon    = require 'sinon'
  expect   = require 'expect'
  eventric = require 'eventric'

  AggregateEntity         = eventric 'AggregateEntity'
  ReadAggregateRoot       = eventric 'ReadAggregateRoot'
  ReadAggregateRepository = eventric 'ReadAggregateRepository'
  Repository              = eventric 'Repository'