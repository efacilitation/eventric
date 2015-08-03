logger = require 'eventric/src/logger'
uidGenerator = require 'eventric/src/uid_generator'

class Projection

  constructor: (@_context) ->
    @_handlerFunctions    = {}
    @_projectionInstances = {}
    @_domainEventsApplied = {}


  initializeInstance: (projectionName, Projection, params) ->
    if typeof Projection is 'function'
      projection = new Projection
    else
      projection = Projection

    if @_context._di
      for diName, diFn of @_context._di
        projection[diName] = diFn

    projectionId = uidGenerator.generateUid()

    aggregateId = null
    projection.$subscribeHandlersWithAggregateId = (_aggregateId) ->
      aggregateId = _aggregateId

    eventNames = null
    @_callInitializeOnProjection projectionName, projection, params
    .then =>
      @_parseEventNamesFromProjection projection
    .then (_eventNames) =>
      eventNames = _eventNames
      @_applyDomainEventsFromStoreToProjection projectionId, projection, eventNames, aggregateId
    .then =>
      @_subscribeProjectionToDomainEvents projectionId, projectionName, projection, eventNames, aggregateId
    .then =>
      @_projectionInstances[projectionId] = projection
    .then ->
      projection.isInitialized = true
    .then ->
      projectionId


  _callInitializeOnProjection: (projectionName, projection, params) ->
    new Promise (resolve, reject) =>
      if not projection.initialize
        logger.debug "[#{@_context.name}] No initialize function on Projection #{projectionName} given, skipping"
        return resolve projection

      logger.debug "[#{@_context.name}] Calling initialize on Projection #{projectionName}"
      projection.initialize params, =>
        logger.debug "[#{@_context.name}] Finished initialize call on Projection #{projectionName}"
        resolve projection


  _parseEventNamesFromProjection: (projection) ->
    new Promise (resolve, reject) ->
      eventNames = []
      for key, value of projection
        if (key.indexOf 'handle') is 0 and (typeof value is 'function')
          eventName = key.replace /^handle/, ''
          eventNames.push eventName
      resolve eventNames


  _applyDomainEventsFromStoreToProjection: (projectionId, projection, eventNames, aggregateId) ->
    @_domainEventsApplied[projectionId] = {}

    if aggregateId
      findEvents = @_context.findDomainEventsByNameAndAggregateId eventNames, aggregateId
    else
      findEvents = @_context.findDomainEventsByName eventNames

    findEvents
    .then (domainEvents) =>
      if not domainEvents or domainEvents.length is 0
        return

      applyDomainEventsToProjectionPromise = Promise.resolve()
      domainEvents.forEach (domainEvent) =>
        applyDomainEventsToProjectionPromise = applyDomainEventsToProjectionPromise.then =>
          @_applyDomainEventToProjection domainEvent, projection
        .then =>
          @_domainEventsApplied[projectionId][domainEvent.id] = true

      return applyDomainEventsToProjectionPromise


  _subscribeProjectionToDomainEvents: (projectionId, projectionName, projection, eventNames, aggregateId) ->
    domainEventHandler = (domainEvent) =>
      if @_domainEventsApplied[projectionId][domainEvent.id]
        return

      @_applyDomainEventToProjection domainEvent, projection
      .then =>
        @_domainEventsApplied[projectionId][domainEvent.id] = true
        return


    subscribeProjectionToDomainEventsPromise = Promise.resolve()
    eventNames.forEach (eventName) =>
      subscribeProjectionToDomainEventsPromise = subscribeProjectionToDomainEventsPromise.then =>
        if aggregateId
          @_context.subscribeToDomainEventWithAggregateId eventName, aggregateId, domainEventHandler
        else
          @_context.subscribeToDomainEvent eventName, domainEventHandler
      .then (subscriberId) =>
        @_handlerFunctions[projectionId] ?= []
        @_handlerFunctions[projectionId].push subscriberId

    return subscribeProjectionToDomainEventsPromise


  _applyDomainEventToProjection: (domainEvent, projection) =>
    Promise.resolve()
    .then =>
      if !projection["handle#{domainEvent.name}"]
        logger.debug "Tried to apply DomainEvent '#{domainEvent.name}' to Projection without a matching handle method"
        return

      return projection["handle#{domainEvent.name}"] domainEvent


  getInstance: (projectionId) ->
    @_projectionInstances[projectionId]


  destroyInstance: (projectionId) ->
    if not @_handlerFunctions[projectionId]
      return Promise.reject new Error 'Missing attribute projectionId'

    unsubscribePromises = []
    for subscriberId in @_handlerFunctions[projectionId]
      unsubscribePromises.push @_context.unsubscribeFromDomainEvent subscriberId

    delete @_handlerFunctions[projectionId]
    delete @_projectionInstances[projectionId]

    Promise.all unsubscribePromises


module.exports = Projection
