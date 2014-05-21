eventric            = require 'eventric'

_                   = eventric 'HelperUnderscore'
ReadAggregateEntity = eventric 'ReadAggregateEntity'
MixinEvents         = eventric 'MixinEvents'

class ReadAggregateRoot extends ReadAggregateEntity

  _.extend @prototype, MixinEvents

module.exports = ReadAggregateRoot
