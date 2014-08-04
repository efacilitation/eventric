eventric = require 'eventric'

_         = require './helper/underscore'
async     = require './helper/async'
Aggregate = require './aggregate'

class Repository

  constructor: (params) ->
    @_aggregateName  = params.aggregateName
    @_AggregateRoot  = params.AggregateRoot
    @_context = params.context

    @_aggregateInstances = {}


  findById: (aggregateId, callback = ->) =>
    new Promise (resolve, reject) =>
      @_findDomainEventsForAggregate aggregateId, (err, domainEvents) =>
        if err
          callback err, null
          reject err
          return

        if not domainEvents.length
          err = "No domainEvents for #{@_aggregateName} Aggregate with #{aggregateId} available"
          callback err, null
          reject err
          return

        aggregate = new Aggregate @_context, @_aggregateName, @_AggregateRoot
        aggregate.applyDomainEvents domainEvents
        aggregate.id = aggregateId

        @_aggregateInstances[aggregateId] = aggregate

        callback null, aggregate.root
        resolve aggregate.root


  _findDomainEventsForAggregate: (aggregateId, callback) ->
    collectionName = "#{@_context.name}.events"
    @_context.getStore().find collectionName, { 'aggregate.name': @_aggregateName, 'aggregate.id': aggregateId }, (err, domainEvents) =>
      return callback err, null if err
      return callback null, [] if domainEvents.length == 0
      callback null, domainEvents


  create: =>
    params = arguments
    if typeof params[params.length-1] is 'function'
      callback = params.pop()

    new Promise (resolve, reject) =>
      aggregate = new Aggregate @_context, @_aggregateName, @_AggregateRoot
      aggregate.create params...
      .then (aggregate) =>
        @_aggregateInstances[aggregate.id] = aggregate
        callback? null, aggregate.id
        resolve aggregate.id


  save: (aggregateId, callback=->) =>
    new Promise (resolve, reject) =>
      aggregate = @_aggregateInstances[aggregateId]
      if not aggregate
        err = new Error 'Tried to save unknown aggregate'
        callback? err, null
        reject err
        return

      collectionName = "#{@_context.name}.events"
      domainEvents   = aggregate.getDomainEvents()

      # TODO: this should be an transaction to guarantee consistency
      async.eachSeries domainEvents, (domainEvent, next) =>
        @_context.getStore().save collectionName, domainEvent, =>
          eventric.log.debug 'Saved DomainEvent', domainEvent
          eventric.nextTick =>
            @_context.getEventBus().publishDomainEvent domainEvent
            eventric.log.debug 'Published DomainEvent', domainEvent
            next null
      , (err) =>
        if err
          callback err, null
          reject err

        else
          resolve aggregate.id
          callback null, aggregate.id


module.exports = Repository
