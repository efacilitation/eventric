###*
* @name Projection
* @module Projection
* @description
*
* Projections can handle muliple DomainEvents and built a denormalized state based on them
###
class Projection

  constructor: (@_eventric) ->
    @log = @_eventric.log
    @_handlerFunctions    = {}
    @_projectionInstances = {}
    @_domainEventsApplied = {}

  ###*
  * @name initializeInstance
  * @module Projection
  * @description Initialize a ProjectionInstance
  *
  * @param {String} projectionName Name of the Projection
  * @param {Function|Object} Projection Function or Object containing a ProjectionDefinition
  ###
  initializeInstance: (projectionName, Projection, params, @_context) ->
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

      domainEventStreamName = null
      projection.$subscribeToDomainEventStream = (_domainEventStreamName) ->
        domainEventStreamName = _domainEventStreamName

      @log.debug "[#{@_context.name}] Clearing ProjectionStores #{projection.stores} of #{projectionName}"
      @_clearProjectionStores projection.stores, projectionName
      .then =>
        @log.debug "[#{@_context.name}] Finished clearing ProjectionStores of #{projectionName}"
        @_injectStoresIntoProjection projectionName, projection
      .then =>
        @_callInitializeOnProjection projectionName, projection, params
      .then =>
        @log.debug "[#{@_context.name}] Replaying DomainEvents against Projection #{projectionName}"
        @_parseEventsMapFromProjection projection
      .then (eventsMap) =>
        @_applyDomainEventsFromStoreToProjection projectionId, projection, eventsMap, aggregateId
      .then (eventNames) =>
        @log.debug "[#{@_context.name}] Finished Replaying DomainEvents against Projection #{projectionName}"
        @_subscribeProjectionToDomainEvents projectionId, projectionName, projection, eventNames, aggregateId, domainEventStreamName
      .then =>
        @_projectionInstances[projectionId] = projection
        event =
          id: projectionId
          projection: projection

        @_context.publish "projection:#{projectionName}:initialized", event
        @_context.publish "projection:#{projectionId}:initialized", event

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
            @log.debug "[#{@_context.name}] Finished Injecting ProjectionStore #{projectionStoreName} into Projection #{projectionName}"
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


  _parseEventsMapFromProjection: (projection) ->
    new Promise (resolve, reject) =>
      eventsMap = {}
      
      for key, value of projection
        if (key.indexOf 'handle') is 0 and (typeof value is 'function')
          eventName = key.replace /^handle/, ''
          eventsMap[@_context.name] ?= []
          eventsMap[@_context.name].push eventName
        else if (key.indexOf 'from') is 0 and (typeof value is 'function')
          contextName = key.replace /^from/, ''
          contextName = contextName.replace /_.*$/, ''
          eventsMap[contextName] ?= []
          eventName = key.replace /.*_handle/, ''
          eventsMap[contextName].push eventName
          
      resolve eventsMap

  _generateSubProjectionStoredDomainEventsHandler: (ready) ->
    return (domainEvents) =>
      new Promise (resolve, reject) =>
        ready
          domainEvents: domainEvents
          promise:
            resolve: resolve
            reject: reject

      
  _createSubProjection: (projectionId, projection, contextName, eventNames) ->
    new Promise (resolve, reject) =>
      remote = false
      subContext = @_eventric.getContext contextName
      if not subContext
        subContext = @_eventric.remote contextName
        remote = true
      
      if not subContext
        err = new Error("Context #{contextName} not found")
        @log.error err
        return reject err
        
      subProjection = {
        $handleStoredDomainEvents: @_generateSubProjectionStoredDomainEventsHandler resolve
      }
      
      for eventName in eventNames
        subProjection["handle#{eventName}"] = projection["from#{contextName}_handle#{eventName}"].bind(projection)
        
      subProjectionName = "_globalProjection_#{projectionId}"
      subContext.addProjection subProjectionName, subProjection
      if subContext._initialized or remote then subContext.initializeProjectionInstance subProjectionName
      
      projection.$subProjections ?= {}
      projection.$subProjections[contextName] = subProjection


  _applyDomainEventsFromStoreToProjection: (projectionId, projection, eventsMap, aggregateId) ->
    @_domainEventsApplied[projectionId] = {}
    promises = []
    for contextName, eventNames of eventsMap when contextName isnt @_context.name
      promises.push @_createSubProjection(projectionId, projection, contextName, eventNames)
      
    if eventsMap[@_context.name]
      if aggregateId
        promises.push @_context.findDomainEventsByNameAndAggregateId eventsMap[@_context.name], aggregateId
      else
        promises.push @_context.findDomainEventsByName eventsMap[@_context.name]
      
    Promise.all promises
    .then (initials) =>
      new Promise (resolve, reject) =>
        domainEvents = []
        for key, value of initials
          if typeof value.domainEvents isnt 'undefined'
            domainEvents = domainEvents.concat value.domainEvents
          else 
            domainEvents = domainEvents.concat value
        
        resolvePromise = =>
          value.promise.resolve(eventsMap) for key, value of initials when typeof value.promise isnt 'undefined'
          resolve eventsMap[@_context.name]
          
        rejectPromise = (err) =>
          value.promise.reject(err) for key, value of initials when typeof value.promise isnt 'undefined'
          resolve err
          
        domainEvents.sort (a, b) ->
          if a.timestamp > b.timestamp then return 1 
          if a.timestamp < b.timestamp then return -1
          return 0
        
        if typeof projection.$handleStoredDomainEvents is 'function'
          projection.$handleStoredDomainEvents(domainEvents)
          .then resolvePromise
          .catch rejectPromise
        else
          @_eventric.eachSeries domainEvents, (domainEvent, next) =>
            @_applyDomainEventToProjection domainEvent, projection
            .then =>
              @_domainEventsApplied[projectionId][domainEvent.id] = true
              next()
    
          , (err) ->
            return rejectPromise(err) if err
            resolvePromise()
  


  _subscribeProjectionToDomainEvents: (projectionId, projectionName, projection, eventNames, aggregateId, domainEventStreamName) ->
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
          @_context.publish "projection:#{projectionName}:changed", event
          @_context.publish "projection:#{projectionId}:changed", event
          done()

        .catch (err) ->
          done err

      if domainEventStreamName
        @_context.subscribeToDomainEventStream domainEventStreamName, domainEventHandler, isAsync: true
        .then (subscriberId) =>
          @_handlerFunctions[projectionId] ?= []
          @_handlerFunctions[projectionId].push subscriberId
          resolve()
        .catch (err) ->
          reject err

      else
        eventric.eachSeries eventNames, (eventName, done) =>
          if aggregateId
            subscriberPromise = @_context.subscribeToDomainEventWithAggregateId eventName, aggregateId, domainEventHandler, isAsync: true
          else
            subscriberPromise = @_context.subscribeToDomainEvent eventName, domainEventHandler, isAsync: true
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


  _applyDomainEventToProjection: (domainEvent, projection) => new Promise (resolve, reject) =>
    if projection["handle#{domainEvent.name}"] and projection["from#{domainEvent.context}_handle#{domainEvent.name}"]
      err = new Error("handle#{domainEvent.name} is ambiguous !")
      @log.error err
      return reject err
      
    handlerFn = projection["handle#{domainEvent.name}"] || projection["from#{domainEvent.context}_handle#{domainEvent.name}"]
    if !handlerFn
      @log.debug "Tried to apply DomainEvent '#{domainEvent.name}' to Projection without a matching handle method"
      return resolve()

    if handlerFn.length == 2
      # promise defined inside the handler
      handlerFn.call projection, domainEvent,
        resolve: resolve
        reject: reject

    else
      # no promise defined inside the handler
      handlerFn.call projection, domainEvent
      resolve()


  ###*
  * @name getInstance
  * @module Projection
  * @description Get a ProjectionInstance
  *
  * @param {String} projectionId ProjectionId
  ###
  getInstance: (projectionId) ->
    @_projectionInstances[projectionId]


  ###*
  * @name destroyInstance
  * @module Projection
  * @description Destroy a ProjectionInstance
  *
  * @param {String} projectionId ProjectionId
  * @param {Object} context Context Instance so we can automatically unsubscribe the Projection from DomainEvents
  ###
  destroyInstance: (projectionId) ->
    if not @_handlerFunctions[projectionId]
      return @_eventric.log.error 'Missing attribute projectionId'

    for subscriberId in @_handlerFunctions[projectionId]
      @_context.unsubscribeFromDomainEvent subscriberId
    delete @_handlerFunctions[projectionId]
    delete @_projectionInstances[projectionId]


module.exports = Projection
