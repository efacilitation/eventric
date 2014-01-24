_               = require 'underscore'
eventric        = require 'eventric'
AggregateEntity = eventric 'AggregateEntity'
MixinSetGet     = eventric 'MixinSetGet'

class ReadAggregateEntity extends AggregateEntity

  _.extend @prototype, MixinSetGet::

module.exports = ReadAggregateEntity