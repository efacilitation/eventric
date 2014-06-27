eventric = require 'eventric'

_                  = eventric.require 'HelperUnderscore'
AggregateService   = eventric.require 'AggregateService'
DomainEventService = eventric.require 'DomainEventService'


class BoundedContext

  constructor: (@name) ->
    @_di = {}
    @_params = {}
    @_aggregateRootClasses = {}
    @_adapterClasses = {}
    @_adapterInstances = {}
    @_commandHandlers = {}
    @_domainEventClasses = {}
    @_domainEventHandlers = {}
    @_readModelClasses = {}
    @_readModelInstances = {}


  initialize: ->
    @_initializeStore()
    @_initializeReadModels()
    @_initializeAdapters()

    @_domainEventService = new DomainEventService
    @_domainEventService.initialize @_store, @
    @_initializeDomainEventHandlers()

    @_aggregateService = new AggregateService
    @_aggregateService.initialize @_store, @_domainEventService, @
    @_initializeAggregateService()

    @_di =
      $aggregate: @_aggregateService
      $adapter: => @getAdapter.apply @, arguments
      $readmodel: => @getReadModel.apply @, arguments
    @


  _initializeReadModels: ->
    for readModelName, ReadModelClass of @_readModelClasses
      @_initializeReadModel readModelName, ReadModelClass


  _initializeReadModel: (readModelName, ReadModelClass) ->
    @_store.collection "#{@name}.ReadModel.#{readModelName}", (err, collection) =>
      readModel = new ReadModelClass
      # TODO: change the injected variable name to "$mongodb, $mysql etc" (@_store.name)
      readModel.$store = collection
      readModel.$adapter = => @getAdapter.apply @, arguments
      if readModel.subscribeToDomainEvents
        for eventName in readModel.subscribeToDomainEvents
          @_subscribeReadModelToDomainEvent readModel, eventName

      @_readModelInstances[readModelName] = readModel


  _subscribeReadModelToDomainEvent: (readModel, eventName) ->
    @addDomainEventHandler eventName, (domainEvent) =>
      @_applyDomainEventToReadModel domainEvent, readModel


  _applyDomainEventToReadModel: (domainEvent, readModel) ->
    if !readModel["handle#{domainEvent.name}"]
      throw new Error "Tried to apply DomainEvent '#{domainEvent.name}' to ReadModel without a matching handle method"

    else
      readModel["handle#{domainEvent.name}"] domainEvent


  _initializeAdapters: ->
    for adapterName, adapterClass of @_adapterClasses
      adapter = new @_adapterClasses[adapterName]
      adapter.initialize?()

      @_adapterInstances[adapterName] = adapter


  _initializeStore: ->
    if @_params.store
      @_store = @_params.store
    else
      globalStore = eventric.get 'store'
      if globalStore
        @_store = globalStore
      else
        throw new Error 'Missing Event Store for Bounded Context'


  _initializeDomainEventHandlers: ->
    for domainEventName, fnArray of @_domainEventHandlers
      for fn in fnArray
        @_domainEventService.on domainEventName, fn


  _initializeAggregateService: ->
    for aggregateName, AggregateRoot of @_aggregateRootClasses
      @_aggregateService.registerAggregateRoot aggregateName, AggregateRoot


  set: (key, value) ->
    @_params[key] = value
    @


  addDomainEvent: (domainEventName, DomainEventClass) ->
    @_domainEventClasses[domainEventName] = DomainEventClass
    @


  addDomainEvents: (domainEventClassesObj) ->
    @addDomainEvent domainEventName, DomainEventClass for domainEventName, DomainEventClass of domainEventClassesObj
    @


  addCommandHandler: (commandHandlerName, commandHandlerFn) ->
    @_commandHandlers[commandHandlerName] = => commandHandlerFn.apply @_di, arguments
    @


  addCommandHandlers: (commandObj) ->
    @addCommandHandler commandHandlerName, commandFunction for commandHandlerName, commandFunction of commandObj
    @


  addAggregate: (aggregateName, AggregateRootClass) ->
    @_aggregateRootClasses[aggregateName] = AggregateRootClass
    @


  addDomainEventHandler: (eventName, handlerFn) ->
    @_domainEventHandlers[eventName] = [] unless @_domainEventHandlers[eventName]
    @_domainEventHandlers[eventName].push => handlerFn.apply @_di, arguments
    @


  addDomainEventHandlers: (domainEventHandlersObj) ->
    @addDomainEventHandler eventName, handlerFn for eventName, handlerFn of domainEventHandlersObj
    @


  addAdapter: (adapterName, adapterClass) ->
    @_adapterClasses[adapterName] = adapterClass
    @


  addAdapters: (adapterObj) ->
    @addAdapter adapterName, fn for adapterName, fn of adapterObj
    @


  addReadModel: (readModelName, ReadModelClass) ->
    @_readModelClasses[readModelName] = ReadModelClass
    @


  addReadModels: (viewsObj) ->
    @addReadModel readModelName, ReadModelClass for readModelName, ReadModelClass of viewsObj
    @


  getReadModel: (readModelName) ->
    @_readModelInstances[readModelName]


  getAdapter: (adapterName) ->
    @_adapterInstances[adapterName]


  getDomainEvent: (domainEventName) ->
    @_domainEventClasses[domainEventName]


  command: (command, callback) ->
    new Promise (resolve, reject) =>
      if @_commandHandlers[command.name]
        @_commandHandlers[command.name] command.params, (err, result) =>
          if err
            reject err
          else
            resolve result
          callback? err, result

      else
        err = new Error "Given command #{command.name} not registered on bounded context"
        reject err
        callback? err, null


  query: (query, callback) ->
    new Promise (resolve, reject) =>
      readModel = @getReadModel query.readModel
      if not readModel
        err = new Error "Given ReadModel #{query.readModel} not found on bounded context"
      if not readModel[query.methodName]
        err = new Error "Given method #{query.methodName} not found on ReadModel #{query.readModel}"

      if err
        reject err
        callback? err, null
      else
        readModel[query.methodName] query.methodParams, (err, result) =>
          if err
            reject err
          else
            resolve result
          callback? err, result


module.exports = BoundedContext
