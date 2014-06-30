eventric = require 'eventric'

_         = eventric.require 'HelperUnderscore'
async     = eventric.require 'HelperAsync'
Aggregate = eventric.require 'Aggregate'

class Repository

  constructor: (params) ->
    @_aggregateName  = params.aggregateName
    @_AggregateRoot  = params.AggregateRoot
    @_boundedContext = params.boundedContext
    @_store          = params.store


  findById: (aggregateId, callback) =>
    return unless @_callbackIsAFunction callback
    @_findDomainEventsForAggregate aggregateId, (err, domainEvents) =>
      aggregate = new Aggregate @_boundedContext, @_aggregateName, @_AggregateRoot
      aggregate.applyDomainEvents domainEvents
      aggregate.id = aggregateId
      callback null, aggregate


  _findDomainEventsForAggregate: (aggregateId, callback) ->
    collectionName = "#{@_boundedContext.name}.events"
    @_store.find collectionName, { 'aggregate.name': @_aggregateName, 'aggregate.id': aggregateId }, (err, domainEvents) =>
      return callback err, null if err
      return callback null, [] if domainEvents.length == 0
      callback null, domainEvents


  _callbackIsAFunction: (callback) ->
    if typeof callback == 'function'
      return true
    else
      throw new Error 'No callback provided'


module.exports = Repository
