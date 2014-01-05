_                   = require 'underscore'
Backbone            = require 'backbone'
eventric            = require 'eventric'
ReadAggregateEntity = eventric 'ReadAggregateEntity'

class ReadAggregateRoot extends ReadAggregateEntity

  _.extend @prototype, Backbone.Events

module.exports = ReadAggregateRoot