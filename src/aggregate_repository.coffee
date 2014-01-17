Repository = require('eventric')('Repository')

class AggregateRepository extends Repository

  constructor: (@_eventStore) ->

  findById: (aggregateName, aggregateId, callback) ->
    # find all domainEvents matching the given aggregateId
    @_eventStore.findByAggregateId aggregateName, aggregateId, (err, domainEvents) =>

      if domainEvents.length == 0
        # nothing found, return null
        callback null, null

      else
        # construct the Aggregate
        AggregateClass = @getClass aggregateName
        if not AggregateClass
          err = new Error "Tried to command not registered Aggregate '#{aggregateName}'"
          callback err, null

        else
          aggregate = new AggregateClass
          aggregate.id = aggregateId

          # apply the domainevents on the ReadAggregate
          for domainEvent in domainEvents
            if domainEvent.aggregate.changed
              aggregate.applyChanges domainEvent.aggregate.changed

          # return the aggregate
          callback null, aggregate


module.exports = AggregateRepository