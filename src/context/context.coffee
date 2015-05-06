# TODO: Split up Context into smaller modules
class Context

  constructor: (@name, @_eventric) ->
    @_initialized = false
    @_params = @_eventric.get()
    @_di = {}
    @_aggregateRootClasses = {}
    @_commandHandlers = {}
    @_queryHandlers = {}
    @_domainEventClasses = {}
    @_domainEventHandlers = {}
    @_projectionClasses = {}
    @_domainEventStreamClasses = {}
    @_domainEventStreamInstances = {}
    @_repositoryInstances = {}
    @_storeClasses = {}
    @_storeInstances = {}
    @_eventBus         = new @_eventric.EventBus @_eventric
    @projectionService = new @_eventric.Projection @_eventric, @
    @log = @_eventric.log


  set: (key, value) ->
    @_params[key] = value
    @


  get: (key) ->
    @_params[key]


  emitDomainEvent: (domainEventName, domainEventPayload) =>
    DomainEventClass = @getDomainEvent domainEventName
    if !DomainEventClass
      throw new Error "Tried to emitDomainEvent '#{domainEventName}' which is not defined"

    domainEvent = @createDomainEvent domainEventName, DomainEventClass, domainEventPayload
    @saveAndPublishDomainEvent domainEvent
    .then =>
      @_eventric.log.debug "Created and Handled DomainEvent in Context", domainEvent


  publishDomainEvent: (domainEvent) =>
    @_eventBus.publishDomainEvent domainEvent


  createDomainEvent: (domainEventName, DomainEventClass, domainEventPayload, aggregate) ->
    payload = {}
    DomainEventClass.apply payload, [domainEventPayload]

    new @_eventric.DomainEvent
      id: @_eventric.generateUid()
      name: domainEventName
      aggregate: aggregate
      context: @name
      payload: payload


  # TODO: Consider renaming. What store? event store? read model store?
  addStore: (storeName, StoreClass, storeOptions = {}) ->
    @_storeClasses[storeName] =
      Class: StoreClass
      options: storeOptions
    @


  defineDomainEvent: (domainEventName, DomainEventClass) ->
    @_domainEventClasses[domainEventName] = DomainEventClass
    @


  defineDomainEvents: (domainEventClassesObj) ->
    @defineDomainEvent domainEventName, DomainEventClass for domainEventName, DomainEventClass of domainEventClassesObj
    @


  addCommandHandler: (commandHandlerName, commandHandlerFn) ->
    @_commandHandlers[commandHandlerName] = commandHandlerFn
    @


  _getAggregateRepository: (aggregateName, command) =>
    repositoriesCache = {} if not repositoriesCache
    if not repositoriesCache[aggregateName]
      AggregateRoot = @_aggregateRootClasses[aggregateName]
      repository = new @_eventric.Repository
        aggregateName: aggregateName
        AggregateRoot: AggregateRoot
        context: @
        eventric: @_eventric
      repositoriesCache[aggregateName] = repository

    repositoriesCache[aggregateName].setCommand command
    repositoriesCache[aggregateName]


  addCommandHandlers: (commandObj) ->
    @addCommandHandler commandHandlerName, commandFunction for commandHandlerName, commandFunction of commandObj
    @


  addQueryHandler: (queryHandlerName, queryHandlerFn) ->
    @_queryHandlers[queryHandlerName] = queryHandlerFn
    @


  addQueryHandlers: (queryObj) ->
    @addQueryHandler queryHandlerName, queryFunction for queryHandlerName, queryFunction of queryObj
    @


  addAggregate: (aggregateName, AggregateRootClass) ->
    @_aggregateRootClasses[aggregateName] = AggregateRootClass
    @


  addAggregates: (aggregatesObj) ->
    @addAggregate aggregateName, AggregateRootClass for aggregateName, AggregateRootClass of aggregatesObj
    @


  subscribeToDomainEvent: (domainEventName, handlerFn) ->
    domainEventHandler = () => handlerFn.apply @_di, arguments
    @_eventBus.subscribeToDomainEvent domainEventName, domainEventHandler


  subscribeToDomainEvents: (domainEventHandlersObj) ->
    @subscribeToDomainEvent domainEventName, handlerFn for domainEventName, handlerFn of domainEventHandlersObj


  # TODO: Remove this when stream subscriptions are implemented
  subscribeToDomainEventWithAggregateId: (domainEventName, aggregateId, handlerFn) ->
    domainEventHandler = () => handlerFn.apply @_di, arguments
    @_eventBus.subscribeToDomainEventWithAggregateId domainEventName, aggregateId, domainEventHandler


  subscribeToAllDomainEvents: (handlerFn) ->
    domainEventHandler = () => handlerFn.apply @_di, arguments
    @_eventBus.subscribeToAllDomainEvents domainEventHandler


  addProjection: (projectionName, ProjectionClass) ->
    @_projectionClasses[projectionName] = ProjectionClass
    @


  addProjections: (viewsObj) ->
    @addProjection projectionName, ProjectionClass for projectionName, ProjectionClass of viewsObj
    @


  getProjectionInstance: (projectionId) ->
    @projectionService.getInstance projectionId


  destroyProjectionInstance: (projectionId) ->
    @projectionService.destroyInstance projectionId, @


  initializeProjectionInstance: (projectionName, params) ->
    if not @_projectionClasses[projectionName]
      err = "Given projection #{projectionName} not registered on context"
      @_eventric.log.error err
      err = new Error err
      return err

    @projectionService.initializeInstance projectionName, @_projectionClasses[projectionName], params


  initialize: ->
    new Promise (resolve, reject) =>
      @log.debug "[#{@name}] Initializing"
      @log.debug "[#{@name}] Initializing Store"
      @_initializeStores()
      .then =>
        @log.debug "[#{@name}] Finished initializing Store"
        @_di =
          $query: => @query.apply @, arguments
          $projectionStore: => @getProjectionStore.apply @, arguments
          $emitDomainEvent: => @emitDomainEvent.apply @, arguments

      .then =>
        @log.debug "[#{@name}] Initializing Projections"
        @_initializeProjections()
      .then =>
        @log.debug "[#{@name}] Finished initializing Projections"
        @log.debug "[#{@name}] Finished initializing"
        @_initialized = true
        resolve()
      .catch (err) ->
        reject err


  _initializeStores: ->
    new Promise (resolve, reject) =>
      stores = []
      for storeName, store of (@_eventric.defaults @_storeClasses, @_eventric.getStores())
        stores.push
          name: storeName
          Class: store.Class
          options: store.options

      @_eventric.eachSeries stores, (store, next) =>
        @log.debug "[#{@name}] Initializing Store #{store.name}"
        @_storeInstances[store.name] = new store.Class
        @_storeInstances[store.name].initialize @, store.options
        .then =>
          @log.debug "[#{@name}] Finished initializing Store #{store.name}"
          next()

        .catch (err) ->
          next err

      , (err) ->
        return reject err if err
        resolve()


  _initializeProjections: ->
    new Promise (resolve, reject) =>
      projections = []
      for projectionName, ProjectionClass of @_projectionClasses
        projections.push
          name: projectionName
          class: ProjectionClass

      @_eventric.eachSeries projections, (projection, next) =>
        eventNames = null
        @log.debug "[#{@name}] Initializing Projection #{projection.name}"
        @projectionService.initializeInstance projection.name, projection.class, {}
        .then (projectionId) =>
          @log.debug "[#{@name}] Finished initializing Projection #{projection.name}"
          next()

        .catch (err) ->
          reject err

      , (err) ->
        return reject err if err
        resolve()


  getProjection: (projectionId) ->
    @projectionService.getInstance projectionId


  # TODO: Rename to getDomainEventClass
  getDomainEvent: (domainEventName) ->
    @_domainEventClasses[domainEventName]


  getDomainEventsStore: ->
    storeName = @get 'default domain events store'
    @_storeInstances[storeName]


  saveAndPublishDomainEvent: (domainEvent) ->  new Promise (resolve, reject) =>
    @getDomainEventsStore().saveDomainEvent domainEvent
    .then =>
      @publishDomainEvent domainEvent
    .then (err) ->
      return reject err if err
      resolve domainEvent


  # TODO: Remove this when stream subscriptions are implemented
  findDomainEventsByName: (findArguments...) ->
    new Promise (resolve, reject) =>
      @getDomainEventsStore().findDomainEventsByName findArguments..., (err, events) ->
        return reject err if err
        resolve events


  # TODO: Remove this when stream subscriptions are implemented
  findDomainEventsByNameAndAggregateId: (findArguments...) ->
    new Promise (resolve, reject) =>
      @getDomainEventsStore().findDomainEventsByNameAndAggregateId findArguments..., (err, events) ->
        return reject err if err
        resolve events


  getProjectionStore: (storeName, projectionName) =>  new Promise (resolve, reject) =>
    if not @_storeInstances[storeName]
      err = "Requested Store with name #{storeName} not found"
      @log.error err
      return reject err

    @_storeInstances[storeName].getProjectionStore projectionName
    .then (projectionStore) ->
      resolve projectionStore

    .catch (err) ->
      reject err


  clearProjectionStore: (storeName, projectionName) =>  new Promise (resolve, reject) =>
    if not @_storeInstances[storeName]
      err = "Requested Store with name #{storeName} not found"
      @log.error err
      return reject err

    @_storeInstances[storeName].clearProjectionStore projectionName
    .then ->
      resolve()

    .catch (err) ->
      reject err


  getEventBus: ->
    @_eventBus


  command: (name, params) ->
    new Promise (resolve, reject) =>
      command =
        id: @_eventric.generateUid()
        name: name
        params: params
      @log.debug 'Got Command', command

      if not @_initialized
        err = 'Context not initialized yet'
        @log.error err
        err = new Error err
        return reject err

      if not @_commandHandlers[name]
        err = "Given command #{name} not registered on context"
        @log.error err
        err = new Error err
        return reject err


      _di = {}
      for diFnName, diFn of @_di
        _di[diFnName] = diFn

      _di.$aggregate =
        create: (aggregateName, aggregateParams...) =>
          repository = @_getAggregateRepository aggregateName, command
          repository.create aggregateParams...

        load: (aggregateName, aggregateId) =>
          repository = @_getAggregateRepository aggregateName, command
          repository.findById aggregateId


      executeCommand = null
      commandHandlerFn = @_commandHandlers[name]
      executeCommand = commandHandlerFn.apply _di, [params]

      Promise.all [executeCommand]
      .then ([result]) =>
        @log.debug 'Completed Command', name
        resolve result
      .catch (error) ->
        reject error


  query: (name, params) ->
    new Promise (resolve, reject) =>
      @log.debug 'Got Query', name

      if not @_initialized
        err = 'Context not initialized yet'
        @log.error err
        err = new Error err
        reject err
        return

      if not @_queryHandlers[name]
        err = "Given query #{name} not registered on context"
        @log.error err
        err = new Error err
        return reject err

      executeQuery = @_queryHandlers[name].apply @_di, [params]

      Promise.all [executeQuery]
      .then ([result]) =>
        @log.debug "Completed Query #{name} with Result #{result}"
        resolve result

      .catch (err) ->
        reject err


module.exports = Context
