EventBus = require 'eventric/src/event_bus'
Projection = require 'eventric/src/projection'
DomainEvent = require 'eventric/src/domain_event'
AggregateRepository = require 'eventric/src/aggregate_repository'
logger = require 'eventric/src/logger'
uidGenerator = require 'eventric/src/uid_generator'

class Context

  constructor: (@name, @_storeDefinition) ->
    @_isInitialized = false
    @_isDestroyed = false
    @_di =
      $query: => @query.apply @, arguments
    @_aggregateClasses = {}
    @_commandHandlers = {}
    @_queryHandlers = {}
    @_domainEventClasses = {}
    @_domainEventHandlers = {}
    @_projectionClasses = {}
    @_repositoryInstances = {}
    @_storeInstance = null
    @_pendingPromises = []
    @_eventBus         = new EventBus
    @projectionService = new Projection @


  defineDomainEvent: (domainEventName, DomainEventClass) ->
    @_domainEventClasses[domainEventName] = DomainEventClass
    @


  defineDomainEvents: (domainEventClassesObj) ->
    @defineDomainEvent domainEventName, DomainEventClass for domainEventName, DomainEventClass of domainEventClassesObj
    @


  addCommandHandlers: (commands) ->
    for commandHandlerName, commandFunction of commands
      @_commandHandlers[commandHandlerName] = commandFunction
    @


  addQueryHandlers: (queries) ->
    for queryHandlerName, queryFunction of queries
      @_queryHandlers[queryHandlerName] = queryFunction
    @


  addAggregate: (aggregateName, AggregateClass) ->
    @_aggregateClasses[aggregateName] = AggregateClass
    @


  subscribeToAllDomainEvents: (handlerFn) ->
    domainEventHandler = => handlerFn.apply @_di, arguments
    @_eventBus.subscribeToAllDomainEvents domainEventHandler


  subscribeToDomainEvent: (domainEventName, handlerFn) ->
    domainEventHandler = => handlerFn.apply @_di, arguments
    @_eventBus.subscribeToDomainEvent domainEventName, domainEventHandler


  subscribeToDomainEvents: (domainEventHandlersObj) ->
    @subscribeToDomainEvent domainEventName, handlerFn for domainEventName, handlerFn of domainEventHandlersObj


  # TODO: Remove this when stream subscriptions are implemented
  subscribeToDomainEventWithAggregateId: (domainEventName, aggregateId, handlerFn) ->
    domainEventHandler = => handlerFn.apply @_di, arguments
    @_eventBus.subscribeToDomainEventWithAggregateId domainEventName, aggregateId, domainEventHandler


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


  initialize: ->
    logger.debug "[#{@name}] Initializing"
    logger.debug "[#{@name}] Initializing Store"
    @_initializeStore()
    .then =>
      logger.debug "[#{@name}] Initializing Projections"
      @_initializeProjections()
    .then =>
      @_isInitialized = true


  _initializeStore: ->
    @_storeInstance = new @_storeDefinition.Class
    initializeStorePromise = @_storeInstance.initialize @, @_storeDefinition.options
    return initializeStorePromise


  _initializeProjections: ->
    initializeProjectionsPromise = Promise.resolve()
    for projectionName, ProjectionClass of @_projectionClasses
      logger.debug "[#{@name}] Initializing Projection #{projectionName}"

      initializeProjectionsPromise = initializeProjectionsPromise.then =>
        @projectionService.initializeInstance projectionName, ProjectionClass, {}
      .then (projectionId) =>
        logger.debug "[#{@name}] Finished initializing Projection #{projectionName}"

    return initializeProjectionsPromise


  createDomainEvent: (domainEventName, DomainEventClass, domainEventPayload, aggregate) ->
    payload = {}
    DomainEventClass.apply payload, [domainEventPayload]

    new DomainEvent
      id: uidGenerator.generateUid()
      name: domainEventName
      aggregate: aggregate
      context: @name
      payload: payload


  initializeProjectionInstance: (projectionName, params) ->
    if not @_projectionClasses[projectionName]
      return Promise.reject new Error "Given projection #{projectionName} not registered on context"

    @projectionService.initializeInstance projectionName, @_projectionClasses[projectionName], params


  getProjection: (projectionId) ->
    @projectionService.getInstance projectionId


  # TODO: Rename to getDomainEventClass
  getDomainEvent: (domainEventName) ->
    @_domainEventClasses[domainEventName]


  getDomainEventsStore: ->
    @_storeInstance


  getEventBus: ->
    @_eventBus


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


  command: (commandName, params) ->
    if @_isDestroyed
      Promise.reject new Error """
        Context #{@name} was destroyed, cannot execute command #{commandName} with arguments #{JSON.stringify(params)}
      """
      return

    executingCommand = new Promise (resolve, reject) =>
      @_verifyContextIsInitialized commandName

      if not @_commandHandlers[commandName]
        throw new Error "Given command #{commandName} not registered on context"

      commandServicesToInject = @_getCommandServicesToInject()

      Promise.resolve @_commandHandlers[commandName].apply commandServicesToInject, [params]
      .then (result) =>
        logger.debug 'Completed Command', commandName
        resolve result
      .catch reject

    @_addPendingPromise executingCommand

    return executingCommand


  _getCommandServicesToInject: ->
    servicesToInject = {}
    for diFnName, diFn of @_di
      servicesToInject[diFnName] = diFn

    servicesToInject.$aggregate =
      create: (aggregateName, aggregateParams...) =>
        aggregateRepository = @_getAggregateRepository aggregateName
        aggregateRepository.create aggregateParams...

      load: (aggregateName, aggregateId) =>
        aggregateRepository = @_getAggregateRepository aggregateName
        aggregateRepository.load aggregateId

    return servicesToInject


  _getAggregateRepository: (aggregateName) =>
    aggregateRepositoriesCache = {} if not aggregateRepositoriesCache
    if not aggregateRepositoriesCache[aggregateName]
      AggregateClass = @_aggregateClasses[aggregateName]
      aggregateRepository = new AggregateRepository
        aggregateName: aggregateName
        AggregateClass: AggregateClass
        context: @
      aggregateRepositoriesCache[aggregateName] = aggregateRepository

    aggregateRepositoriesCache[aggregateName]


  _addPendingPromise: (pendingPromise) ->
    alwaysResolvingPromise = pendingPromise.catch ->
    @_pendingPromises.push alwaysResolvingPromise
    alwaysResolvingPromise.then =>
      @_pendingPromises.splice @_pendingPromises.indexOf(alwaysResolvingPromise), 1


  query: (queryName, params) ->
    new Promise (resolve, reject) =>
      logger.debug 'Got Query', queryName

      @_verifyContextIsInitialized queryName

      if not @_queryHandlers[queryName]
        reject new Error "Given query #{queryName} not registered on context"
        return

      Promise.resolve @_queryHandlers[queryName].apply @_di, [params]
      .then (result) =>
        logger.debug "Completed Query #{queryName} with Result #{result}"
        resolve result
      .catch reject


  _verifyContextIsInitialized: (methodName) ->
    if not @_isInitialized
      throw new Error "Context #{@name} not initialized yet, cannot execute #{methodName}"


  destroy: ->
    Promise.all(@_pendingPromises).then =>
      @_eventBus.destroy().then =>
        @_isDestroyed = true


module.exports = Context
