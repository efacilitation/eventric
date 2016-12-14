AggregateRepository = require 'eventric/aggregate_repository'
domainEventService = require 'eventric/domain_event/domain_event_service'

class Context

  constructor: (@name) ->
    EventBus = require 'eventric/event_bus'
    Projection = require 'eventric/projection'

    @_logger = require('eventric').getLogger()
    @_isInitialized = false
    @_isDestroyed = false
    # TODO: Consider removing this "DI" since queries can be executed by simply accessing the context
    @_di =
      $query: => @query.apply @, arguments
    @_aggregateClasses = {}
    @_commandHandlers = {}
    @_queryHandlers = {}
    @_domainEventPayloadConstructors = {}
    @_domainEventHandlers = {}
    @_projectionObjects = []
    @_repositoryInstances = {}
    @_storeInstance = null
    @_pendingPromises = []
    @_eventBus = new EventBus
    @_projectionService = new Projection @


  initialize: ->
    startOfInitialization = new Date
    @_logger.debug "eventric context \"#{@name}\" initializing"
    @_initializeStore()
    .then =>
      @_initializeProjections()
    .then =>
      endOfInitialization = new Date
      durationOfInitialization = endOfInitialization - startOfInitialization
      @_logger.debug "eventric context \"#{@name}\" initialized after #{durationOfInitialization}ms"
      @_isInitialized = true


  _initializeStore: ->
    # TODO: Test
    eventric = require '../eventric'
    storeDefinition = eventric.getStoreDefinition()
    @_storeInstance = new storeDefinition.Class
    initializeStorePromise = @_storeInstance.initialize @, storeDefinition.options
    return initializeStorePromise


  _initializeProjections: ->
    initializeProjectionsPromise = Promise.resolve()
    @_projectionObjects.forEach (projectionObject) =>
      initializeProjectionsPromise = initializeProjectionsPromise.then =>
        @_projectionService.initializeInstance projectionObject, {}
    return initializeProjectionsPromise


  defineDomainEvent: (domainEventName, DomainEventPayloadConstructor) ->
    @_domainEventPayloadConstructors[domainEventName] = DomainEventPayloadConstructor
    @


  defineDomainEvents: (domainEventClassesObj) ->
    for domainEventName, DomainEventPayloadConstructor of domainEventClassesObj
      @defineDomainEvent domainEventName, DomainEventPayloadConstructor
    @


  addCommandHandlers: (commandHandlers) ->
    for commandHandlerName, commandFunction of commandHandlers
      @_commandHandlers[commandHandlerName] = commandFunction
    @


  addQueryHandlers: (queryHandlers) ->
    for queryHandlerName, queryFunction of queryHandlers
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


  unsubscribeFromDomainEvent: (subscriberId) ->
    @_eventBus.unsubscribe subscriberId


  addProjection: (projectionObject) ->
    @_projectionObjects.push projectionObject
    @


  destroyProjectionInstance: (projectionId) ->
    @_projectionService.destroyInstance projectionId, @


  getDomainEventPayloadConstructor: (domainEventName) ->
    @_domainEventPayloadConstructors[domainEventName]


  getDomainEventsStore: ->
    @_storeInstance


  getEventBus: ->
    @_eventBus


  # TODO: Remove this when stream subscriptions are implemented
  findDomainEventsByName: (findArguments...) ->
    new Promise (resolve, reject) =>
      @getDomainEventsStore().findDomainEventsByName findArguments..., (err, domainEvents) ->
        return reject err if err
        domainEvents = domainEventService.sortDomainEventsById domainEvents
        resolve domainEvents


  # TODO: Remove this when stream subscriptions are implemented
  findDomainEventsByNameAndAggregateId: (findArguments...) ->
    new Promise (resolve, reject) =>
      @getDomainEventsStore().findDomainEventsByNameAndAggregateId findArguments..., (err, domainEvents) ->
        return reject err if err
        domainEvents = domainEventService.sortDomainEventsById domainEvents
        resolve domainEvents


  command: (commandName, params) ->
    if @_isDestroyed
      paramsWithHiddenPasswordValue = @_hidePasswordValue params
      return Promise.reject new Error """
        Context #{@name} was destroyed, cannot execute command #{commandName} with arguments
        #{JSON.stringify(paramsWithHiddenPasswordValue)}
      """

    executingCommand = new Promise (resolve, reject) =>
      @_verifyContextIsInitialized commandName

      if not @_commandHandlers[commandName]
        throw new Error "Given command #{commandName} not registered on context"

      commandServicesToInject = @_getCommandServicesToInject()

      Promise.resolve()
      .then =>
        @_commandHandlers[commandName].apply commandServicesToInject, [params]
      .then (result) =>
        @_logger.debug 'Completed Command', commandName
        resolve result
      .catch (error) =>
        paramsWithHiddenPasswordValue = @_hidePasswordValue params
        commandErrorMessage = """
          Command "#{commandName}" with arguments #{JSON.stringify(paramsWithHiddenPasswordValue)} of context "#{@name}"
          rejects with an error
        """

        if not error
          reject new Error commandErrorMessage
          return

        error = @_extendError error, commandErrorMessage
        reject error


    @_addPendingPromise executingCommand

    return executingCommand


  _hidePasswordValue: (params) ->
    if params.password
      params.password = '******'
    return params


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


  _extendError: (error, additionalMessage) ->
    error.originalErrorMessage = error.message
    error.message = "#{additionalMessage} - original error message: #{error.originalErrorMessage}"
    return error


  _getAggregateRepository: (aggregateName) =>
    new AggregateRepository
      aggregateName: aggregateName
      AggregateClass: @_aggregateClasses[aggregateName]
      context: @


  _addPendingPromise: (pendingPromise) ->
    alwaysResolvingPromise = pendingPromise.catch ->
    @_pendingPromises.push alwaysResolvingPromise
    alwaysResolvingPromise.then =>
      @_pendingPromises.splice @_pendingPromises.indexOf(alwaysResolvingPromise), 1


  query: (queryName, params) ->
    new Promise (resolve, reject) =>
      @_logger.debug 'Got Query', queryName

      @_verifyContextIsInitialized queryName

      if not @_queryHandlers[queryName]
        reject new Error "Given query #{queryName} not registered on context"
        return

      Promise.resolve()
      .then =>
        @_queryHandlers[queryName].apply @_di, [params]
      .then (result) =>
        @_logger.debug "Completed Query #{queryName} with Result #{result}"
        resolve result
      .catch (error) =>
        paramsWithHiddenPasswordValue = @_hidePasswordValue params
        queryErrorMessage = """
          Query "#{queryName}" with arguments #{JSON.stringify(paramsWithHiddenPasswordValue)} of context "#{@name}"
          rejects with an error
        """

        if not error
          reject new Error queryErrorMessage
          return

        error = @_extendError error, queryErrorMessage
        reject error


  _verifyContextIsInitialized: (methodName) ->
    if not @_isInitialized
      throw new Error "Context #{@name} not initialized yet, cannot execute #{methodName}"


  destroy: ->
    Promise.all @_pendingPromises
    .then =>
      @_eventBus.destroy()
    .then =>
      @_isDestroyed = true


module.exports = Context
