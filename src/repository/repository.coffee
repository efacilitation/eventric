class Repository

  constructor: (params, @_eventric) ->
    @_aggregateName  = params.aggregateName
    @_AggregateRoot  = params.AggregateRoot
    @_context        = params.context
    @_eventric       = params.eventric

    @_command = {}
    @_aggregateInstances = {}
    @_store = @_context.getDomainEventsStore()


  findById: (aggregateId, callback = ->) =>
    new Promise (resolve, reject) =>
      @_findDomainEventsForAggregate aggregateId, (err, domainEvents) =>
        if err
          callback err, null
          reject err
          return

        if not domainEvents.length
          err = "No domainEvents for #{@_aggregateName} Aggregate with #{aggregateId} available"
          @_eventric.log.error err
          callback err, null
          reject err
          return

        aggregate = new @_eventric.Aggregate @_context, @_eventric, @_aggregateName, @_AggregateRoot
        aggregate.applyDomainEvents domainEvents
        aggregate.id = aggregateId
        aggregate.root.$id = aggregateId
        aggregate.root.$save = =>
          @save aggregate.id

        commandId = @_command.id ? 'nocommand'
        @_aggregateInstances[commandId] ?= {}
        @_aggregateInstances[commandId][aggregateId] = aggregate

        callback null, aggregate.root
        resolve aggregate.root


  _findDomainEventsForAggregate: (aggregateId, callback) ->
    @_store.findDomainEventsByAggregateId aggregateId, (err, domainEvents) ->
      return callback err, null if err
      return callback null, [] if domainEvents.length == 0
      callback null, domainEvents


  create: (params) =>
    new Promise (resolve, reject) =>
      aggregate = new @_eventric.Aggregate @_context, @_eventric, @_aggregateName, @_AggregateRoot
      aggregate.id = @_eventric.generateUid()

      if typeof aggregate.root.create isnt 'function'
        err = "No create function on aggregate"
        @_eventric.log.error err
        reject new Error err

      aggregate.root.$id = aggregate.id
      aggregate.root.$save = =>
        @save aggregate.id

      # TODO: needs refactoring
      commandId = @_command.id ? 'nocommand'
      @_aggregateInstances[commandId] ?= {}
      @_aggregateInstances[commandId][aggregate.id] = aggregate

      createAggregate = aggregate.root.create params

      Promise.resolve createAggregate
      .then ->
        resolve aggregate.root
      .catch reject


  save: (aggregateId) =>
    new Promise (resolve, reject) =>
      commandId = @_command.id ? 'nocommand'
      aggregate = @_aggregateInstances[commandId][aggregateId]
      if not aggregate
        errorMessage = "Tried to save unknown aggregate #{@_aggregateName}"
        @_eventric.log.error errorMessage
        throw new Error errorMessage

      domainEvents = aggregate.getDomainEvents()
      if domainEvents.length < 1
        errorMessage = "Tried to save 0 DomainEvents from Aggregate #{@_aggregateName}"
        @_eventric.log.debug errorMessage, @_command
        throw new Error errorMessage

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


  setCommand: (command) ->
    @_command = command


module.exports = Repository
