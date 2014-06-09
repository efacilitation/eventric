eventric = require 'eventric'

_           = eventric.require 'HelperUnderscore'
Aggregate   = eventric.require 'Aggregate'
DomainEvent = eventric.require 'DomainEvent'

class AggregateRepository
  _aggregateDefinitions: {}

  constructor: (@_eventStore) ->


  findById: (aggregateName, aggregateId, callback) ->
    # find all domainEvents matching the given aggregateId
    @_eventStore.find aggregateName, { 'aggregate.id': aggregateId }, (err, events) =>
      return callback err, null if err

      # nothing found, return null
      return callback null, null if events.length == 0

      # get the corresponding class
      aggregateDefinition = @getAggregateDefinition aggregateName
      if not aggregateDefinition
        err = new Error "Tried to command not registered Aggregate '#{aggregateName}'"
        callback err, null
        return

      # construct the Aggregate and set the id
      aggregate = new Aggregate aggregateName, aggregateDefinition
      aggregate.id = aggregateId

      # TODO: this should be part of the event store itself?
      domainEvents = []
      for event in events
        domainEvents.push new DomainEvent event

      # apply the domain events on the aggregate
      aggregate.applyDomainEvents domainEvents

      # return the aggregate
      callback null, aggregate


  registerAggregateDefinition: (aggregateName, aggregateDefinition) ->
    @_aggregateDefinitions[aggregateName] = aggregateDefinition


  getAggregateDefinition: (aggregateName) ->
    return false unless aggregateName of @_aggregateDefinitions
    @_aggregateDefinitions[aggregateName]


module.exports = AggregateRepository
