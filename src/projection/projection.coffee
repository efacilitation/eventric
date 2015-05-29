class Projection

  constructor: (@_eventric, @_context) ->
    @log = @_eventric.log
    @_handlerFunctions    = {}
    @_projectionInstances = {}
    @_domainEventsApplied = {}


  initializeInstance: (projectionName, Projection, params) ->
    new Promise (resolve, reject) =>

      if typeof Projection is 'function'
        projection = new Projection
      else
        projection = Projection

      if @_context._di
        for diName, diFn of @_context._di
          projection[diName] = diFn

      projectionId = @_eventric.generateUid()

      aggregateId = null
      projection.$subscribeHandlersWithAggregateId = (_aggregateId) ->
        aggregateId = _aggregateId


      @log.debug "[#{@_context.name}] Clearing ProjectionStores #{projection.stores} of #{projectionName}"
      eventNames = null
      @_clearProjectionStores projection.stores, projectionName
      .then =>
        @log.debug "[#{@_context.name}] Finished clearing ProjectionStores of #{projectionName}"
        @_injectStoresIntoProjection projectionName, projection
      .then =>
        @_callInitializeOnProjection projectionName, projection, params
      .then =>
        @log.debug "[#{@_context.name}] Replaying DomainEvents against Projection #{projectionName}"
        @_parseEventNamesFromProjection projection
      .then (_eventNames) =>
        eventNames = _eventNames
        @_applyDomainEventsFromStoreToProjection projectionId, projection, eventNames, aggregateId
      .then =>
        @log.debug "[#{@_context.name}] Finished Replaying DomainEvents against Projection #{projectionName}"
        @_subscribeProjectionToDomainEvents projectionId, projectionName, projection, eventNames, aggregateId
      .then =>
        @_projectionInstances[projectionId] = projection
        event =
          id: projectionId
          projection: projection

        resolve projectionId

      .catch (err) ->
        reject err


  _callInitializeOnProjection: (projectionName, projection, params) ->
    new Promise (resolve, reject) =>
      if not projection.initialize
        @log.debug "[#{@_context.name}] No initialize function on Projection #{projectionName} given, skipping"
        return resolve projection

      @log.debug "[#{@_context.name}] Calling initialize on Projection #{projectionName}"
      projection.initialize params, =>
        @log.debug "[#{@_context.name}] Finished initialize call on Projection #{projectionName}"
        resolve projection


  _injectStoresIntoProjection: (projectionName, projection) ->
    new Promise (resolve, reject) =>
      if not projection.stores
        return resolve()

      projection["$store"] ?= {}
      @_eventric.eachSeries projection.stores, (projectionStoreName, next) =>
        @log.debug "[#{@_context.name}] Injecting ProjectionStore #{projectionStoreName} into Projection #{projectionName}"
        @_context.getProjectionStore projectionStoreName, projectionName
        .then (projectionStore) =>
          if projectionStore
            projection["$store"][projectionStoreName] = projectionStore
            @log.debug "[#{@_context.name}] Finished Injecting ProjectionStore #{projectionStoreName} \
            into Projection #{projectionName}"
            next()

        .catch (err) ->
          next err

      , (err) ->
        return reject err if err
        resolve()


  _clearProjectionStores: (projectionStores, projectionName) ->
    new Promise (resolve, reject) =>
      if not projectionStores
        return resolve()

      @_eventric.eachSeries projectionStores, (projectionStoreName, next) =>
        @log.debug "[#{@_context.name}] Clearing ProjectionStore #{projectionStoreName} for #{projectionName}"
        @_context.clearProjectionStore projectionStoreName, projectionName
        .then =>
          @log.debug "[#{@_context.name}] Finished clearing ProjectionStore #{projectionStoreName} for #{projectionName}"
          next()
        .catch (err) ->
          next err
      , (err) ->
        resolve()


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

      promise = new Promise (resolve) -> resolve()
      domainEvents.forEach (domainEvent) =>
        promise = promise.then =>
          @_applyDomainEventToProjection domainEvent, projection
          .then =>
            @_domainEventsApplied[projectionId][domainEvent.id] = true

      return promise


  _subscribeProjectionToDomainEvents: (projectionId, projectionName, projection, eventNames, aggregateId) ->
    new Promise (resolve, reject) =>
      domainEventHandler = (domainEvent, done = ->) =>
        if @_domainEventsApplied[projectionId][domainEvent.id]
          return done()

        @_applyDomainEventToProjection domainEvent, projection
        .then =>
          @_domainEventsApplied[projectionId][domainEvent.id] = true
          event =
            id: projectionId
            projection: projection
            domainEvent: domainEvent
          done()

        .catch (err) ->
          done err

      @_eventric.eachSeries eventNames, (eventName, done) =>
        if aggregateId
          subscriberPromise = @_context.subscribeToDomainEventWithAggregateId eventName, aggregateId, domainEventHandler
        else
          subscriberPromise = @_context.subscribeToDomainEvent eventName, domainEventHandler
        subscriberPromise
        .then (subscriberId) =>
          @_handlerFunctions[projectionId] ?= []
          @_handlerFunctions[projectionId].push subscriberId
          done()
        .catch (err) ->
          done err
      , (err) ->
        return reject err if err
        resolve()


  _applyDomainEventToProjection: (domainEvent, projection) =>
    new Promise (resolve, reject) =>
      if !projection["handle#{domainEvent.name}"]
        @log.debug "Tried to apply DomainEvent '#{domainEvent.name}' to Projection without a matching handle method"
        resolve()
        return

      handleDomainEvent = projection["handle#{domainEvent.name}"] domainEvent
      Promise.all [handleDomainEvent]
      .then ([result]) ->
        resolve result


  getInstance: (projectionId) ->
    @_projectionInstances[projectionId]


  destroyInstance: (projectionId) ->
    if not @_handlerFunctions[projectionId]
      return @_eventric.log.error 'Missing attribute projectionId'

    unsubscribePromises = []
    for subscriberId in @_handlerFunctions[projectionId]
      unsubscribePromises.push @_context.unsubscribeFromDomainEvent subscriberId

    delete @_handlerFunctions[projectionId]
    delete @_projectionInstances[projectionId]

    Promise.all unsubscribePromises


module.exports = Projection
