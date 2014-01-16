Repository = require('eventric')('Repository')

class AggregateRepository extends Repository

  constructor: (@_eventStore) ->

  findById: (aggregateName, id, callback) ->
    # find all domainEvents matching the given aggregateId
    @_eventStore.findByAggregateId id, (err, domainEvents) =>

      if domainEvents.length == 0
        err = new Error "EventStore did not found any DomainEvent for aggregateId #{id}"
        callback err, null

      else
        # construct the Aggregate
        AggregateClass = @getClass aggregateName
        if not AggregateClass
          err = new Error "Tried to command not registered Aggregate '#{aggregateName}'"
          callback err, null

        else
          aggregate = new AggregateClass

          # apply the domainevents on the ReadAggregate
          aggregate.applyChanges domainEvent.aggregate.changed for domainEvent in domainEvents
          aggregate.id = id

          if aggregate.checkins?
            console.log 'REPO BUILT', aggregate.checkins

          # return the aggregate
          callback null, aggregate


module.exports = AggregateRepository