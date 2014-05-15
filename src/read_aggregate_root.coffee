eventric            = require 'eventric'

_                   = eventric 'HelperUnderscore'
ReadAggregateEntity = eventric 'ReadAggregateEntity'
MixinSnapshot       = eventric 'MixinSnapshot'
MixinEvents         = eventric 'MixinEvents'

class ReadAggregateRoot extends ReadAggregateEntity

  _.extend @prototype, MixinEvents
  _.extend @prototype, MixinSnapshot::

module.exports = ReadAggregateRoot
