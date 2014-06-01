eventric = require 'eventric'

_                 = eventric.require 'HelperUnderscore'
async             = eventric.require 'HelperAsync'
ReadAggregateRoot = eventric.require 'ReadAggregateRoot'

class ReadAggregateRepository

  constructor: (@_aggregateName, @_eventStore) ->


  findById: (aggregateId, callback) =>
    return unless @_callbackIsAFunction callback

    # create the ReadAggregate instance
    readAggregateObj = @getReadAggregateObj @_aggregateName

    # TODO: return if @_checkReadAggregateClassNotSet ReadAggregateClass, callback
    if not readAggregateObj
      err = new Error "Tried 'findById' on not registered ReadAggregate for '#{@_aggregateName}'"
      return callback err, null

    # TODO: @_findDomainEventsForAggregateId aggregateId, callback, (err, domainEvents) =>
    @_eventStore.find @_aggregateName, { 'aggregate.id': aggregateId }, (err, domainEvents) =>
      return callback err, null if err
      return callback null, [] if domainEvents.length == 0

      readAggregate = new ReadAggregateRoot
      _.extend readAggregate, readAggregateObj

      # apply the domainevents on the ReadAggregate
      for domainEvent in domainEvents when domainEvent.aggregate?.changed
        readAggregate.applyChanges domainEvent.aggregate.changed
        readAggregate.id = aggregateId

      # return the readAggregate
      callback null, readAggregate


  find: (query, callback) ->
    return unless @_callbackIsAFunction callback

    # get ReadAggregates matching the query
    @findIds query, (err, aggregateIds) =>
      return callback err, null if err

      readAggregates = []
      # execute findById for every aggregateId found
      async.whilst (=> aggregateIds.length > 0),

        ((callbackAsync) =>
          aggregateId = aggregateIds.shift()
          @findById aggregateId, (err, readAggregate) =>
            return callbackAsync err if err
            return callbackAsync null if readAggregate.length == 0
            readAggregates.push readAggregate
            callbackAsync null
        ),

        ((err) =>
          return callback err, null if err
          callback null, readAggregates
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


  _readAggregateObjs: {}

  registerReadAggregateObj: (aggregateName, readAggregateObj) ->
    @_readAggregateObjs[aggregateName] = readAggregateObj


  getReadAggregateObj: (aggregateName) ->
    return false unless aggregateName of @_readAggregateObjs
    @_readAggregateObjs[aggregateName]


module.exports = ReadAggregateRepository
