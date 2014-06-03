eventric = require 'eventric'

_             = eventric.require 'HelperUnderscore'
AggregateRoot = eventric.require 'AggregateRoot'


class AggregateRepository
  _aggregateClasses: {}

  constructor: (@_eventStore) ->


  findById: (aggregateName, aggregateId, callback) ->
    # find all domainEvents matching the given aggregateId
    @_eventStore.find aggregateName, { 'aggregate.id': aggregateId }, (err, domainEvents) =>
      return callback err, null if err

      # nothing found, return null
      return callback null, null if domainEvents.length == 0

      # get the corresponding class
      Aggregate = @getAggregateClass aggregateName
      if not Aggregate
        err = new Error "Tried to command not registered Aggregate '#{aggregateName}'"
        callback err, null
        return

      # construct the Aggregate and set the id
      aggregate = new Aggregate
      _.extend aggregate, new AggregateRoot aggregateName
      aggregate.id = aggregateId

      # apply the aggregate changes inside the domainevents on the ReadAggregate
      for domainEvent in domainEvents
        if domainEvent.aggregate.changed
          aggregate.applyChanges domainEvent.aggregate.changed

      # return the aggregate
      callback null, aggregate


  registerAggregateClass: (aggregateName, Aggregate) ->
    @_aggregateClasses[aggregateName] = Aggregate


  getAggregateClass: (aggregateName) ->
    return false unless aggregateName of @_aggregateClasses
    @_aggregateClasses[aggregateName]


module.exports = AggregateRepository
