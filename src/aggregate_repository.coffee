_        = require 'underscore'
eventric = require 'eventric'

MixinRegisterAndGetClass = eventric 'MixinRegisterAndGetClass'


class AggregateRepository

  _.extend @prototype, MixinRegisterAndGetClass::

  constructor: (@_eventStore) ->

  findById: (aggregateName, aggregateId, callback) ->
    # find all domainEvents matching the given aggregateId
    @_eventStore.find aggregateName, { 'aggregate.id': aggregateId }, (err, domainEvents) =>
      return callback err, null if err

      # nothing found, return null
      return callback null, null if domainEvents.length == 0

      # get the corresponding class
      AggregateClass = @getClass aggregateName
      if not AggregateClass
        err = new Error "Tried to command not registered Aggregate '#{aggregateName}'"
        callback err, null
        return

      # construct the Aggregate and set the id
      aggregate = new AggregateClass
      aggregate.id = aggregateId

      # apply the aggregate changes inside the domainevents on the ReadAggregate
      for domainEvent in domainEvents
        if domainEvent.aggregate.changed
          aggregate.applyChanges domainEvent.aggregate.changed

      # return the aggregate
      callback null, aggregate


module.exports = AggregateRepository