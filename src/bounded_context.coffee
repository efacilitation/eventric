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
  _applicationServiceCommands: {}
  _domainEventClasses: {}
  _domainEventHandlers: {}
  _readModelClasses: {}

  initialize: ->
    @_initializeEventStore()

    @_domainEventService = new DomainEventService
    @_domainEventService.initialize @_eventStore
    @_initializeDomainEventHandlers()

    @_aggregateService = new AggregateService
    @_aggregateService.initialize @_eventStore, @_domainEventService, @
    @_initializeAggregateService()

    @_di =
      $aggregate: @_aggregateService
      $adapter: => @getAdapter.apply @, arguments
    @


  _initializeEventStore: ->
    if @_params.store
      @_eventStore = @_params.store
    else
      globalStore = eventric.get 'store'
      if globalStore
        @_eventStore = globalStore
      else
        throw new Error 'Missing Event Store for Bounded Context'


  _initializeDomainEventHandlers: ->
    for domainEventName, fnArray of @_domainEventHandlers
      for fn in fnArray
        @_domainEventService.on domainEventName, fn


  _initializeAggregateService: () ->
    for aggregateName, aggregateDefinition of @_aggregateRootClasses
      @_aggregateService.registerAggregateRoot aggregateName, aggregateDefinition


  set: (key, value) ->
    @_params[key] = value
    @


  addDomainEvent: (domainEventName, DomainEventClass) ->
    @_domainEventClasses[domainEventName] = DomainEventClass
    @


  addDomainEvents: (domainEventClassesObj) ->
    @addDomainEvent domainEventName, DomainEventClass for domainEventName, DomainEventClass of domainEventClassesObj
    @


  addCommand: (commandName, fn) ->
    @_applicationServiceCommands[commandName] = => fn.apply @_di, arguments
    @


  addCommands: (commandObj) ->
    @addCommand commandName, commandFunction for commandName, commandFunction of commandObj
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


  getView: (readModelName) ->
    ReadModelClass = @_readModelClasses[readModelName]
    view = new ReadModelClass
    # TODO: apply correct domainevents to view


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
      if @_applicationServiceCommands[command.name]
        @_applicationServiceCommands[command.name] command.params, (err, result) =>
          resolve result
          callback? err, result
      else
        err = new Error "Given command #{command.name} not registered on bounded context"
        reject err
        callback? err, null


module.exports = BoundedContext
