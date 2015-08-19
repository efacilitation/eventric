Aggregate = require 'eventric/aggregate'
logger = require 'eventric/logger'
uuidGenerator = require 'eventric/uuid_generator'

class AggregateRepository

  constructor: (params) ->
    @_aggregateName = params.aggregateName
    @_AggregateClass = params.AggregateClass
    @_context = params.context
    @_store = @_context.getDomainEventsStore()


  load: (aggregateId) =>
    new Promise (resolve, reject) =>
      @_store.findDomainEventsByAggregateId aggregateId, (error, domainEvents) =>
        if error
          reject error
          return

        if not domainEvents.length
          reject new Error "No domainEvents for #{@_aggregateName} Aggregate with #{aggregateId} available"
          return

        aggregate = new Aggregate @_context, @_aggregateName, @_AggregateClass
        aggregate.applyDomainEvents domainEvents
        aggregate.id = aggregate.instance.$id = aggregateId
        aggregate.instance.$save = =>
          @save aggregate

        resolve aggregate.instance


  create: (params) =>
    new Promise (resolve, reject) =>
      aggregate = new Aggregate @_context, @_aggregateName, @_AggregateClass

      if typeof aggregate.instance.create isnt 'function'
        throw new Error "No create function on aggregate"

      # TODO: What in the world is going on here! - Why is there no setter for this attribute?
      aggregate.id = aggregate.instance.$id = uuidGenerator.generateUuid()
      aggregate.instance.$save = =>
        @save aggregate

      Promise.resolve aggregate.instance.create params
      .then ->
        resolve aggregate.instance
      .catch reject


  save: (aggregate) =>
    new Promise (resolve, reject) =>
      if not aggregate
        throw new Error "Tried to save unknown aggregate #{@_aggregateName}"

      domainEvents = aggregate.getDomainEvents()
      if domainEvents.length < 1
        throw new Error "Tried to save 0 DomainEvents from Aggregate #{@_aggregateName}"

      logger.debug "Going to Save and Publish #{domainEvents.length} DomainEvents from Aggregate #{@_aggregateName}"

      # TODO: this should be an transaction to guarantee consistency
      saveDomainEventQueue = Promise.resolve()
      domainEvents.forEach (domainEvent) =>
        saveDomainEventQueue = saveDomainEventQueue.then =>
          @_store.saveDomainEvent domainEvent
        .then ->
          logger.debug 'Saved DomainEvent', domainEvent


      saveDomainEventQueue
      .then =>
        domainEvents.forEach (domainEvent) =>
          logger.debug 'Publishing DomainEvent', domainEvent
          @_context.getEventBus().publishDomainEvent domainEvent
          .catch (error) ->
            logger.error error.stack || error
      .then ->
        resolve aggregate.id
      .catch reject


module.exports = AggregateRepository
