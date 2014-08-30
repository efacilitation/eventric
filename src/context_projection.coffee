eventric = require 'eventric'
async    = require './helper/async'

class Projection

  constructor: ->
    @log = eventric.log


  initializeProjections: (context) ->
    new Promise (resolve, reject) =>
      async.eachSeries context._projectionClasses, (projection, next) =>
        eventNames = null
        projectionName = projection.name
        @log.debug "[#{context.name}] Initializing Projection #{projectionName}"
        @_initializeProjection projection, context
        .then (projection) =>
          @log.debug "[#{context.name}] Finished initializing Projection #{projectionName}"

          @log.debug "[#{context.name}] Replaying DomainEvents against Projection #{projectionName}"
          eventNames = []
          for key, value of projection
            if (key.indexOf 'handle') is 0 and (typeof value is 'function')
              eventName = key.replace /^handle/, ''
              eventNames.push eventName

          @_applyDomainEventsFromStoreToProjection projection, eventNames, context
        .then (projection) =>
          @log.debug "[#{context.name}] Finished Replaying DomainEvents against Projection #{projectionName}"
          @_subscribeProjectionToDomainEvents projection, eventNames, context
          context._projectionInstances[projectionName] = projection
          resolve()

        .catch (err) ->
          reject err

      , (err) =>
        return reject err if err
        resolve()


  _initializeProjection: (projectionObj, context) ->
    new Promise (resolve, reject) =>

      projectionName = projectionObj.name
      ProjectionClass = projectionObj.class
      projection = new ProjectionClass
      for diName, diFn of context._di
        projection[diName] = diFn

      if not projection.stores
        err = "No Stores configured on Projection #{projectionObj.name}"
        @log.error err
        throw new Error err

      projection["$store"] ?= {}

      @log.debug "[#{context.name}] Clearing Projections"
      @_clearProjectionStores projection.stores, projectionName, context
      .then =>
        @log.debug "[#{context.name}] Finished clearing Projections"
        async.eachSeries projection.stores, (projectionStoreName, next) =>
          @log.debug "[#{context.name}] Injecting ProjectionStore #{projectionStoreName} into Projection #{projectionName}"
          context.getProjectionStore projectionStoreName, projectionName, (err, projectionStore) =>
            if projectionStore
              projection["$store"][projectionStoreName] = projectionStore
              @log.debug "[#{context.name}] Finished Injecting ProjectionStore #{projectionStoreName} into Projection #{projectionName}"
              next()

        , (err) =>
          if not projection.initialize
            @log.debug "[#{context.name}] No initialize function on Projection #{projectionName} given, skipping"
            return resolve projection

          @log.debug "[#{context.name}] Calling initialize on Projection #{projectionName}"
          projection.initialize ->
            @log.debug "[#{context.name}] Finished initialize call on Projection #{projectionName}"
            resolve projection

      .catch (err) ->
        reject err


  _clearProjectionStores: (projectionStores, projectionName, context) ->
    new Promise (resolve, reject) =>
      async.eachSeries projectionStores, (projectionStoreName, next) =>
        @log.debug "[#{context.name}] Clearing ProjectionStore #{projectionStoreName} for #{projectionName}"
        context.clearProjectionStore projectionStoreName, projectionName, =>
          @log.debug "[#{context.name}] Finished clearing ProjectionStore #{projectionStoreName} for #{projectionName}"
          next()
      , (err) ->
        resolve()


  _applyDomainEventsFromStoreToProjection: (projection, eventNames, context) ->
    new Promise (resolve, reject) =>
      context.getDomainEventsStore().findDomainEventsByName eventNames, (err, events) =>
        if not events or events.length is 0
          return resolve projection, eventNames

        async.eachSeries events, (event, next) =>
          @_applyDomainEventToProjection event, projection, =>
            next()

        , (err) =>
          reject err if err
          resolve projection, eventNames


  _subscribeProjectionToDomainEvents: (projection, eventNames, context) ->
    domainEventHandler = (domainEvent, done) =>
      @_applyDomainEventToProjection domainEvent, projection, done
    for eventName in eventNames
      context.subscribeToDomainEvent eventName, domainEventHandler, isAsync: true


  _applyDomainEventToProjection: (domainEvent, projection, callback = ->) =>
    if !projection["handle#{domainEvent.name}"]
      err = new Error "Tried to apply DomainEvent '#{domainEvent.name}' to Projection without a matching handle method"

    else
      projection["handle#{domainEvent.name}"] domainEvent, callback


module.exports = new Projection