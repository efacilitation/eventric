eventric = require 'eventric'

_                  = eventric.require 'HelperUnderscore'
AggregateService   = eventric.require 'AggregateService'
DomainEventService = eventric.require 'DomainEventService'


class BoundedContext
  _di: {}
  _params: {}
  _aggregateRootClasses: {}
  _adapters: {}
  _adapterInstances: {}
  _commandHandlers: {}
  _domainEventClasses: {}
  _domainEventHandlers: {}
  _readModelClasses: {}

  constructor: (@name) ->


  initialize: ->
    @_initializeStore()

    @_domainEventService = new DomainEventService
    @_domainEventService.initialize @_store, @
    @_initializeDomainEventHandlers()

    @_aggregateService = new AggregateService
    @_aggregateService.initialize @_store, @_domainEventService, @
    @_initializeAggregateService()

    @_di =
      $aggregate: @_aggregateService
      $adapter: => @getAdapter.apply @, arguments
    @


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


  addAdapter: (adapterName, adapterClass) ->
    @_adapters[adapterName] = adapterClass
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
    ReadModelClass = @_readModelClasses[readModelName]
    readModel = new ReadModelClass

    @_store.find @name, name: $in: readModel.subscribeToDomainEvents
    , (domainEvents) =>
      for domainEvent in domainEvents
        @_applyDomainEventToReadModel domainEvent, readModel

    readModel


  _applyDomainEventToReadModel: (domainEvent, readModel) ->
    if !readModel["handle#{domainEvent.name}"]
      console.log "Tried to apply DomainEvent '#{domainEvent.name}' to ReadModel without a matching handle method"

    else
      readModel["handle#{domainEvent.name}"] domainEvent


  getAdapter: (adapterName) ->
    # return cache if available
    return @_adapterInstances[adapterName] if @_adapterInstances[adapterName]

    # build adapter
    adapter = new @_adapters[adapterName]
    adapter.initialize?()

    # cache
    @_adapterInstances[adapterName] = adapter

    # return
    adapter


  getDomainEvent: (domainEventName) ->
    @_domainEventClasses[domainEventName]


  command: (command, callback) ->
    new Promise (resolve, reject) =>
      if @_commandHandlers[command.name]
        @_commandHandlers[command.name] command.params, (err, result) =>
          resolve result
          callback? err, result
      else
        err = new Error "Given command #{command.name} not registered on bounded context"
        reject err
        callback? err, null


module.exports = BoundedContext
