_                   = require 'underscore'
Backbone            = require 'backbone'
eventric            = require 'eventric'

ReadAggregateEntity = eventric 'ReadAggregateEntity'
MixinSnapshot       = eventric 'MixinSnapshot'
MixinSetGet         = eventric 'MixinSetGet'

class ReadAggregateRoot extends ReadAggregateEntity

  _.extend @prototype, Backbone.Events
  _.extend @prototype, MixinSnapshot::

module.exports = ReadAggregateRoot