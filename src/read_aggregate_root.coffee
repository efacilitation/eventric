eventric            = require 'eventric'
ReadAggregateEntity = eventric 'ReadAggregateEntity'

class ReadAggregateRoot extends ReadAggregateEntity

  constructor: (aggregateData) ->
    for key, value of aggregateData
      @[key] = value


module.exports = ReadAggregateRoot