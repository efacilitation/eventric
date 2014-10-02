eventric = require 'eventric'

class Projection

  constructor: ->
    @log = eventric.log
    @_handlerFunctions    = {}
    @_projectionInstances = {}
    @_domainEventsApplied = {}


  ###*
  * @name initializeInstance
  *
  * @module Projection
  ###
  initializeInstance: (projectionName, Projection, params, context) ->
    new Promise (resolve, reject) =>

      if typeof Projection is 'function'
        projection = new Projection
      else
        projection = Projection

      if context._di
        for diName, diFn of context._di
          projection[diName] = diFn

      projectionId = eventric.generateUid()

      aggregateId = null
      projection.$subscribeHandlersWithAggregateId = (_aggregateId) ->
        aggregateId = _aggregateId

      domainEventStreamName = null
      projection.$subscribeToDomainEventStream = (_domainEventStreamName) ->
        domainEventStreamName = _domainEventStreamName

      @log.debug "[#{context.name}] Clearing Projections"
      @_clearProjectionStores projection.stores, projectionName, context
      .then =>
        @log.debug "[#{context.name}] Finished clearing Projections"
        @_injectStoresIntoProjection projectionName, projection, context
      .then =>
        @_callInitializeOnProjection projectionName, projection, params, context
      .then =>
        @log.debug "[#{context.name}] Replaying DomainEvents against Projection #{projectionName}"
        @_parseEventNamesFromProjection projection
      .then (eventNames) =>
        @_applyDomainEventsFromStoreToProjection projectionId, projection, eventNames, aggregateId, context
      .then (eventNames) =>
        @log.debug "[#{context.name}] Finished Replaying DomainEvents against Projection #{projectionName}"
        @_subscribeProjectionToDomainEvents projectionId, projectionName, projection, eventNames, aggregateId, domainEventStreamName, context
      .then =>
        @_projectionInstances[projectionId] = projection
        event =
          id: projectionId
          projection: projection
        context.publish "projection:#{projectionName}:initialized", event
        context.publish "projection:#{projectionId}:initialized", event

        resolve projectionId

      .catch (err) ->
        reject err


  _callInitializeOnProjection: (projectionName, projection, params, context) ->
    new Promise (resolve, reject) =>
      if not projection.initialize
        @log.debug "[#{context.name}] No initialize function on Projection #{projectionName} given, skipping"
        return resolve projection

      @log.debug "[#{context.name}] Calling initialize on Projection #{projectionName}"
      projection.initialize params, =>
        @log.debug "[#{context.name}] Finished initialize call on Projection #{projectionName}"
        resolve projection


  _injectStoresIntoProjection: (projectionName, projection, context) ->
    new Promise (resolve, reject) =>
      if not projection.stores
        return resolve()

      projection["$store"] ?= {}
      eventric.eachSeries projection.stores, (projectionStoreName, next) =>
        @log.debug "[#{context.name}] Injecting ProjectionStore #{projectionStoreName} into Projection #{projectionName}"
        context.getProjectionStore projectionStoreName, projectionName, (err, projectionStore) =>
          if projectionStore
            projection["$store"][projectionStoreName] = projectionStore
            @log.debug "[#{context.name}] Finished Injecting ProjectionStore #{projectionStoreName} into Projection #{projectionName}"
            next()

      , (err) ->
        return reject err if err
        resolve()


  _clearProjectionStores: (projectionStores, projectionName, context) ->
    new Promise (resolve, reject) =>
      if not projectionStores
        return resolve()

      eventric.eachSeries projectionStores, (projectionStoreName, next) =>
        @log.debug "[#{context.name}] Clearing ProjectionStore #{projectionStoreName} for #{projectionName}"
        context.clearProjectionStore projectionStoreName, projectionName, =>
          @log.debug "[#{context.name}] Finished clearing ProjectionStore #{projectionStoreName} for #{projectionName}"
          next()
      , (err) ->
        resolve()


  _parseEventNamesFromProjection: (projection) ->
    new Promise (resolve, reject) =>
      eventNames = []
      for key, value of projection
        if (key.indexOf 'handle') is 0 and (typeof value is 'function')
          eventName = key.replace /^handle/, ''
          eventNames.push eventName
      resolve eventNames


  _applyDomainEventsFromStoreToProjection: (projectionId, projection, eventNames, aggregateId, context) ->
    new Promise (resolve, reject) =>
      @_domainEventsApplied[projectionId] = {}

      if aggregateId
        findEvents = context.findDomainEventsByNameAndAggregateId eventNames, aggregateId
      else
        findEvents = context.findDomainEventsByName eventNames

      findEvents.then (domainEvents) =>
        if not domainEvents or domainEvents.length is 0
          return resolve eventNames

        eventric.eachSeries domainEvents, (domainEvent, next) =>
          @_applyDomainEventToProjection domainEvent, projection, =>
            @_domainEventsApplied[projectionId][domainEvent.id] = true
            next()

        , (err) ->
          return reject err if err
          resolve eventNames

      findEvents.catch (err) ->
        reject err


  _subscribeProjectionToDomainEvents: (projectionId, projectionName, projection, eventNames, aggregateId, domainEventStreamName, context) ->
    new Promise (resolve, reject) =>
      domainEventHandler = (domainEvent, done = ->) =>
        if @_domainEventsApplied[projectionId][domainEvent.id]
          return done()

        @_applyDomainEventToProjection domainEvent, projection, =>
          @_domainEventsApplied[projectionId][domainEvent.id] = true
          event =
            id: projectionId
            projection: projection
            domainEvent: domainEvent
          context.publish "projection:#{projectionName}:changed", event
          context.publish "projection:#{projectionId}:changed", event

          done()

      if domainEventStreamName
        subscriberId = context.subscribeToDomainEventStream domainEventStreamName, domainEventHandler, isAsync: true
        @_handlerFunctions[projectionId] ?= []
        @_handlerFunctions[projectionId].push subscriberId

      else
        for eventName in eventNames
          if aggregateId
            subscriberId = context.subscribeToDomainEventWithAggregateId eventName, aggregateId, domainEventHandler, isAsync: true
          else
            subscriberId = context.subscribeToDomainEvent eventName, domainEventHandler, isAsync: true

          @_handlerFunctions[projectionId] ?= []
          @_handlerFunctions[projectionId].push subscriberId

      resolve()


  _applyDomainEventToProjection: (domainEvent, projection, callback) =>
    if !projection["handle#{domainEvent.name}"]
      @log.debug "Tried to apply DomainEvent '#{domainEvent.name}' to Projection without a matching handle method"
      return callback()

    if projection["handle#{domainEvent.name}"].length == 2
      # done callback defined inside the handler
      projection["handle#{domainEvent.name}"] domainEvent, callback

    else
      # no callback defined inside the handler
      projection["handle#{domainEvent.name}"] domainEvent
      callback()


  ###*
  * @name getInstance
  *
  * @module Projection
  ###
  getInstance: (projectionId) ->
    @_projectionInstances[projectionId]


  ###*
  * @name destroyInstance
  *
  * @module Projection
  ###
  destroyInstance: (projectionId, context) ->
    if not @_handlerFunctions[projectionId]
      return eventric.log.error 'Missing attribute projectionId'

    for subscriberId in @_handlerFunctions[projectionId]
      context.unsubscribeFromDomainEvent subscriberId
    delete @_handlerFunctions[projectionId]
    delete @_projectionInstances[projectionId]


module.exports = new Projection
