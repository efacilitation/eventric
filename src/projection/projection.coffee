eventric = require 'eventric'

class Projection

  constructor: ->
    @log = eventric.log
    @_handlerFunctions    = {}
    @_projectionInstances = {}
    @_domainEventsApplied = {}


  initializeInstance: (projectionObj, params, context) ->
    new Promise (resolve, reject) =>

      projectionName = projectionObj.name
      ProjectionClass = projectionObj.class
      projection = new ProjectionClass
      if context._di
        for diName, diFn of context._di
          projection[diName] = diFn

      projectionId = eventric.generateUid()

      aggregateId = null
      projection.$subscribeHandlersWithAggregateId = (_aggregateId) ->
        aggregateId = _aggregateId

      @log.debug "[#{context.name}] Clearing Projections"
      @_clearProjectionStores projection.stores, projectionName, context
      .then =>
        @log.debug "[#{context.name}] Finished clearing Projections"
        @_injectStoresIntoProjection projectionName, projection, context
      .then =>
        @_callInitializeOnProjection projectionName, projection, params, context
      .then =>
        @log.debug "[#{context.name}] Replaying DomainEvents against Projection #{projectionName}"
        eventNames = []
        for key, value of projection
          if (key.indexOf 'handle') is 0 and (typeof value is 'function')
            eventName = key.replace /^handle/, ''
            eventNames.push eventName

        @_applyDomainEventsFromStoreToProjection projectionId, projection, eventNames, aggregateId, context
      .then (eventNames) =>
        @log.debug "[#{context.name}] Finished Replaying DomainEvents against Projection #{projectionName}"
        @_subscribeProjectionToDomainEvents projectionId, projectionName, projection, eventNames, aggregateId, context
      .then =>
        @_projectionInstances[projectionId] = projection
        context.publish "projection:#{projectionName}:initialized",
          id: projectionId
          projection: projection
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


  _subscribeProjectionToDomainEvents: (projectionId, projectionName, projection, eventNames, aggregateId, context) ->
    new Promise (resolve, reject) =>
      domainEventHandler = (domainEvent, done) =>
        if @_domainEventsApplied[projectionId][domainEvent.id]
          return done()

        @_applyDomainEventToProjection domainEvent, projection, =>
          @_domainEventsApplied[projectionId][domainEvent.id] = true
          context.publish "projection:#{projectionName}:changed",
            id: projectionId
            projection: projection
          done()

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


  getInstance: (projectionId) ->
    @_projectionInstances[projectionId]


  destroyInstance: (projectionId, context) ->
    if not @_handlerFunctions[projectionId]
      return eventric.log.error 'Missing attribute projectionId'

    for subscriberId in @_handlerFunctions[projectionId]
      context.unsubscribeFromDomainEvent subscriberId
    delete @_handlerFunctions[projectionId]
    delete @_projectionInstances[projectionId]


module.exports = new Projection
