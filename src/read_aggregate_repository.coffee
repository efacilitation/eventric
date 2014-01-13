Repository = require('eventric')('Repository')

class ReadAggregateRepository extends Repository

  constructor: (@_eventStore) ->

  findById: (readAggregateName, id, callback) ->
    # find domain events matching the aggregate id
    @_eventStore.findByAggregateId id, (err, domainEvents) =>

      if domainEvents.length == 0
        err = new Error "EventStore did not found any DomainEvent for aggregateId #{id}"
        callback err, null

      else
        # create the ReadAggregate instance
        ReadAggregateClass = @getClass readAggregateName

        if not ReadAggregateClass
          err = new Error "Tried to findById on not registered ReadAggregate '#{readAggregateName}'"
          callback err, null

        readAggregate = new ReadAggregateClass

        # apply the domainevents on the ReadAggregate
        readAggregate._applyChanges domainEvent.aggregate.changed for domainEvent in domainEvents
        readAggregate.id = id

        # return the readAggregate
        callback null, readAggregate

  find: (query, callback) ->
    # get AggregateIds matching the query
    aggregateIds = @findIds query

    # now find ReadAggregates matching the AggregateIds and return as array
    # TODO implement cursor-behaviour like https://github.com/mongodb/node-mongodb-native
    results = []
    results.push @findById aggregateId for aggregateId in aggregateIds

    callback null, results


  findIds: (query, callback) ->
    # ask the adapter to find the ids and return them
    @_eventStore.findAggregateIds query, (err, aggregateIds) =>

      callback null, aggregateIds

  findOne: (query, callback) ->
    result = @find query

    callback null, result[0]


module.exports = ReadAggregateRepository