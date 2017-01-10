Aggregate = require 'eventric/aggregate'
uuidGenerator = require 'eventric/uuid_generator'
domainEventService = require 'eventric/domain_event/domain_event_service'

class AggregateRepository

  constructor: (params) ->
    @_logger = require('eventric').getLogger()
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

        if not domainEvents?.length
          reject new Error "No domainEvents for aggregate of type #{@_aggregateName} with #{aggregateId} available"
          return

        domainEvents = domainEventService.sortDomainEventsById domainEvents

        aggregateDeletedEvent = null
        for domainEvent in domainEvents by -1
          if domainEvent.name.indexOf("#{@_aggregateName}Deleted") > -1
            aggregateDeletedEvent = domainEvent
            break

        if aggregateDeletedEvent?
          reject new Error "Aggregate of type #{@_aggregateName} with id #{aggregateId} is marked as deleted because of \
            domain event #{aggregateDeletedEvent.name} with domain event id #{aggregateDeletedEvent.id}"
          return

        aggregate = new Aggregate @_context, @_aggregateName, @_AggregateClass
        aggregate.setId aggregateId
        aggregate.applyDomainEvents domainEvents
        @_installSaveFunctionOnAggregateInstance aggregate

        resolve aggregate.instance


  # TODO: Rename to "new" and remove automagic call of create() function on aggregate
  create: (params, id = null) =>
    Promise.resolve().then =>
      aggregate = new Aggregate @_context, @_aggregateName, @_AggregateClass

      if typeof aggregate.instance.create isnt 'function'
        throw new Error 'No create function on aggregate'

      if id?
        aggregate.setId id
      else
        aggregate.setId uuidGenerator.generateUuid()

      @_installSaveFunctionOnAggregateInstance aggregate

      Promise.resolve aggregate.instance.create params
      .then ->
        return aggregate.instance


  _installSaveFunctionOnAggregateInstance: (aggregate) ->
    aggregate.instance.$save = =>
      @save aggregate


  save: (aggregate) =>
    Promise.resolve()
    .then =>
      if not aggregate
        throw new Error "Tried to save unknown aggregate #{@_aggregateName}"

      domainEvents = aggregate.getNewDomainEvents()
      if not domainEvents?.length
        throw new Error "No new domain events to save for aggregate of type #{@_aggregateName} with id #{aggregate.id}"

      @_logger.debug "Going to Save and Publish #{domainEvents.length} DomainEvents from Aggregate #{@_aggregateName}"

      # TODO: Think about how to achieve "transactions" to guarantee consistency when saving multiple events
      saveDomainEventQueue = Promise.resolve()
      savedDomainEvents = []
      domainEvents.forEach (domainEvent) =>
        saveDomainEventQueue = saveDomainEventQueue.then =>
          @_store.saveDomainEvent domainEvent
          .then (domainEvent) ->
            savedDomainEvents.push domainEvent

      saveDomainEventQueue
      .then =>
        savedDomainEvents.forEach (domainEvent) =>
          @_context.getEventBus().publishDomainEvent domainEvent
          .catch (error) =>
            @_logger.error error, '\n', error.stack

        return aggregate.id


module.exports = AggregateRepository
