class Repository

  constructor: (params) ->
    @_aggregateName = params.aggregateName
    @_AggregateClass = params.AggregateClass
    @_context = params.context
    @_eventric = params.eventric
    @_store = @_context.getDomainEventsStore()


  findById: (aggregateId) =>
    new Promise (resolve, reject) =>
      @_store.findDomainEventsByAggregateId aggregateId, (error, domainEvents) =>
        if error
          reject error
          return

        if not domainEvents.length
          reject new Error "No domainEvents for #{@_aggregateName} Aggregate with #{aggregateId} available"
          return

        aggregate = new @_eventric.Aggregate @_context, @_eventric, @_aggregateName, @_AggregateClass
        aggregate.applyDomainEvents domainEvents
        aggregate.id = aggregate.instance.$id = aggregateId
        aggregate.instance.$save = =>
          @save aggregate

        resolve aggregate.instance


  create: (params) =>
    new Promise (resolve, reject) =>
      aggregate = new @_eventric.Aggregate @_context, @_eventric, @_aggregateName, @_AggregateClass

      if typeof aggregate.instance.create isnt 'function'
        throw new Error "No create function on aggregate"

      aggregate.id = aggregate.instance.$id = @_eventric.generateUid()
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

      @_eventric.log.debug "Going to Save and Publish #{domainEvents.length} DomainEvents from Aggregate #{@_aggregateName}"

      # TODO: this should be an transaction to guarantee consistency
      saveDomainEventQueue = new Promise (resolve) -> resolve()
      domainEvents.forEach (domainEvent) =>
        saveDomainEventQueue = saveDomainEventQueue.then =>
          @_store.saveDomainEvent domainEvent
        .then =>
          @_eventric.log.debug "Saved DomainEvent", domainEvent


      saveDomainEventQueue
      .then =>
        domainEvents.forEach (domainEvent) =>
          @_eventric.log.debug "Publishing DomainEvent", domainEvent
          @_context.getEventBus().publishDomainEvent domainEvent
          .catch (error) =>
            @_eventric.log.error error.stack || error
      .then ->
        resolve aggregate.id
      .catch reject


module.exports = Repository
