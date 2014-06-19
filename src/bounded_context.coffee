eventric = require 'eventric'

_                  = eventric.require 'HelperUnderscore'
AggregateService   = eventric.require 'AggregateService'
Repository         = eventric.require 'Repository'
DomainEventService = eventric.require 'DomainEventService'


class BoundedContext
  _di: {}
  _params: {}
  _aggregateRootClasses: {}
  _repositories: {}
  _repositoryInstances: {}
  _adapters: {}
  _adapterInstances: {}
  _applicationServiceCommands: {}
  _applicationServiceQueries: {}
  _domainEventClasses: {}
  _domainEventHandlers: {}

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
      $repository: => @getRepository.apply @, arguments
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


  addApplicationService: (serviceObj) ->
    for type, typeObj of serviceObj
      switch type
        when 'commands' then @addCommands serviceObj[type]
        when 'queries' then @addQueries serviceObj[type]
    @


  addCommand: (commandName, fn) ->
    @_applicationServiceCommands[commandName] = => fn.apply @_di, arguments
    @


  addCommands: (commandObj) ->
    @addCommand commandName, commandFunction for commandName, commandFunction of commandObj
    @


  addQuery: (queryName, fn) ->
    @_applicationServiceQueries[queryName] = => fn.apply @_di, arguments
    @


  addQueries: (queryObj) ->
    @addQuery queryName, queryFunction for queryName, queryFunction of queryObj
    @


  addAggregate: (aggregateName, AggregateRootClass) ->
    @_aggregateRootClasses[aggregateName] = AggregateRootClass
    @


  addRepository: (aggregateName, repository) ->
    @_repositories[aggregateName] = repository
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


  getRepository: (aggregateName) ->
    # return cache if available
    return @_repositoryInstances[aggregateName] if @_repositoryInstances[aggregateName]

    # TODO: constructing while get may a violation of SRP?
    # define name and event store
    repositoryParams =
      aggregateName: aggregateName
      AggregateRoot: @_aggregateRootClasses[aggregateName]
      eventStore: @_eventStore

    # build repository
    repository = new Repository repositoryParams

    # extend repository with custom repository if available
    if @_repositories[aggregateName]
      _.extend repository, @_repositories[aggregateName]

    # cache
    @_repositoryInstances[aggregateName] = repository

    # return
    repository


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


  query: (query, callback) ->
    new Promise (resolve, reject) =>
      if @_applicationServiceQueries[query.name]
        @_applicationServiceQueries[query.name] query.params, (err, result) =>
          resolve result
          callback? err, result
      else
        errorMessage = "Given query #{query.name} not registered on bounded context"
        error = new Error errorMessage
        reject error
        callback? error, null


module.exports = BoundedContext
