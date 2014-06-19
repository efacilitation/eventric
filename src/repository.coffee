eventric = require 'eventric'

_         = eventric.require 'HelperUnderscore'
async     = eventric.require 'HelperAsync'
Aggregate = eventric.require 'Aggregate'

class Repository

  constructor: (params) ->
    @_aggregateName  = params.aggregateName
    @_AggregateRoot  = params.AggregateRoot
    @_boundedContext = params.boundedContext
    @_eventStore     = params.eventStore


  findById: (aggregateId, callback) =>
    return unless @_callbackIsAFunction callback

    # TODO: @_findDomainEventsForAggregateId aggregateId, callback, (err, domainEvents) =>
    @_eventStore.find @_aggregateName, { 'aggregate.id': aggregateId }, (err, domainEvents) =>
      return callback err, null if err
      return callback null, [] if domainEvents.length == 0

      aggregate = new Aggregate @_boundedContext, @_aggregateName, @_AggregateRoot
      aggregate.applyDomainEvents domainEvents

      aggregate.id = aggregateId

      callback null, aggregate


  find: (query, callback) ->
    return unless @_callbackIsAFunction callback

    @findIds query, (err, aggregateIds) =>
      return callback err, null if err

      aggregates = []
      async.whilst (=> aggregateIds.length > 0),

        ((callbackAsync) =>
          aggregateId = aggregateIds.shift()
          @findById aggregateId, (err, aggregate) =>
            return callbackAsync err if err
            return callbackAsync null if aggregate.length == 0
            aggregates.push aggregate
            callbackAsync null
        ),

        ((err) =>
          return callback err, null if err
          callback null, aggregates
        )


  findOne: (query, callback) ->
    return unless @_callbackIsAFunction callback

    # TODO: returns only the first result, should actually do a limited query against the store
    @find query, (err, results) =>
      return callback err, null if err
      return callback null, false if results.length == 0
      callback null, results[0]


  findIds: (query, callback) =>
    return unless @_callbackIsAFunction callback

    # ask the adapter to find the ids and return them
    @_eventStore.find @_aggregateName, query, { 'aggregate.id': 1 }, (err, results) =>
      return callback err, null if err

      aggregateIds = []
      aggregateIds.push result.aggregate.id for result in results when result.aggregate.id not in aggregateIds

      callback null, aggregateIds


  _callbackIsAFunction: (callback) ->
    if typeof callback == 'function'
      return true

    else
      throw new Error 'No callback provided'


module.exports = Repository
