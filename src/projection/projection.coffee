logger = require 'eventric/logger'
uuidGenerator = require 'eventric/uuid_generator'

class ProjectionService

  constructor: (@_context) ->
    @_handlerFunctions    = {}
    @_projectionInstances = {}
    @_domainEventsApplied = {}


  initializeInstance: (projectionInstance, params) ->
    if @_context._di
      for diName, diFn of @_context._di
        projectionInstance[diName] = diFn

    projectionId = uuidGenerator.generateUuid()

    aggregateId = null
    projectionObject.$subscribeHandlersWithAggregateId = (_aggregateId) ->
      if not _aggregateId
        throw new Error 'Missing aggregate id'
      aggregateId = _aggregateId

    eventNames = null
    @_callInitializeOnProjection projectionInstance, params
    .then =>
      @_parseEventNamesFromProjection projectionInstance
    .then (_eventNames) =>
      eventNames = _eventNames
      @_applyDomainEventsFromStoreToProjection projectionId, projectionInstance, eventNames, aggregateId
    .then =>
      @_subscribeProjectionToDomainEvents projectionId, projectionInstance, eventNames, aggregateId
    .then =>
      @_projectionInstances[projectionId] = projectionInstance
    .then ->
      projectionInstance.isInitialized = true
    .then ->
      projectionId


  _callInitializeOnProjection: (projection, params) ->
    new Promise (resolve, reject) ->
      if not projection.initialize
        return resolve projection

      projection.initialize params, ->
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


  _subscribeProjectionToDomainEvents: (projectionId, projection, eventNames, aggregateId) ->
    domainEventHandler = (domainEvent) =>
      if @_domainEventsApplied[projectionId][domainEvent.id]
        return

      @_applyDomainEventToProjection domainEvent, projection
      .then =>
        @_domainEventsApplied[projectionId][domainEvent.id] = true
        return


    @_handlerFunctions[projectionId] = []
    subscribeProjectionToDomainEventsPromise = Promise.resolve()
    eventNames.forEach (eventName) =>
      subscribeProjectionToDomainEventsPromise = subscribeProjectionToDomainEventsPromise.then =>
        if aggregateId
          @_context.subscribeToDomainEventWithAggregateId eventName, aggregateId, domainEventHandler
        else
          @_context.subscribeToDomainEvent eventName, domainEventHandler
      .then (subscriberId) =>
        @_handlerFunctions[projectionId].push subscriberId

    return subscribeProjectionToDomainEventsPromise


  _applyDomainEventToProjection: (domainEvent, projection) ->
    Promise.resolve()
    .then ->
      if !projection["handle#{domainEvent.name}"]
        logger.debug "Tried to apply DomainEvent '#{domainEvent.name}' to Projection without a matching handle method"
        return

      return projection["handle#{domainEvent.name}"] domainEvent


  getInstance: (projectionId) ->
    @_projectionInstances[projectionId]


  destroyInstance: (projectionId) ->
    if not projectionId
      return Promise.reject new Error 'Missing projection id'

    if not @_handlerFunctions[projectionId]
      return Promise.reject new Error "Projection with id \"#{projectionId}\" is not initialized"


    unsubscribePromises = []
    for subscriberId in @_handlerFunctions[projectionId]
      unsubscribePromises.push @_context.unsubscribeFromDomainEvent subscriberId

    delete @_handlerFunctions[projectionId]
    delete @_projectionInstances[projectionId]

    Promise.all unsubscribePromises


module.exports = ProjectionService
