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


  _callbackIsAFunction: (callback) ->
    if typeof callback == 'function'
      return true

    else
      throw new Error 'No callback provided'


module.exports = Repository
