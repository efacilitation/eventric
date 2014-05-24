eventric            = require 'eventric'

_                   = eventric.require 'HelperUnderscore'
ReadAggregateEntity = eventric.require 'ReadAggregateEntity'
MixinEvents         = eventric.require 'MixinEvents'

class ReadAggregateRoot extends ReadAggregateEntity

  _.extend @prototype, MixinEvents

module.exports = ReadAggregateRoot
