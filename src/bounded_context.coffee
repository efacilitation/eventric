eventric = require 'eventric'

_                  = eventric.require 'HelperUnderscore'
AggregateService   = eventric.require 'AggregateService'
Repository         = eventric.require 'Repository'
DomainEventService = eventric.require 'DomainEventService'


class BoundedContext
  _di: {}
  _params: {}
  _aggregateDefinitions: {}
  _readAggregateDefinitions: {}
  _repositories: {}
  _repositoryInstances: {}
  _adapters: {}
  _adapterInstances: {}
  _applicationServiceCommands: {}
  _applicationServiceQueries: {}
  _domainEventHandlers: {}


  initialize: (callback) ->
    @_initializeEventStore =>
      @_domainEventService = new DomainEventService @_eventStore
      @_aggregateService   = new AggregateService @_eventStore, @_domainEventService

      @_di =
        aggregate: @_aggregateService
        repository: => @getRepository.apply @, arguments
        adapter: => @getAdapter.apply @, arguments

      @_initializeAggregateService()
      @_initializeDomainEventHandlers()

      callback? null


  _initializeEventStore: (next) ->
    if @_params.store
      @_eventStore = @_params.store
      next()
    else
      # TODO: refactor to use a pseudo-store (which just logs that it wont save anything)
      @_eventStore = require 'eventric-store-mongodb'
      @_eventStore.initialize (err) =>
        next()


  _initializeAggregateService: () ->
    for aggregateName, aggregateDefinition of @_aggregateDefinitions
      @_aggregateService.registerAggregateDefinition aggregateName, aggregateDefinition


  _initializeDomainEventHandlers: ->
    for domainEventName, fnArray of @_domainEventHandlers
      for fn in fnArray
        @_domainEventService.on domainEventName, fn


  set: (key, value) ->
    @_params[key] = value


  addApplicationService: (serviceObj) ->
    for type, typeObj of serviceObj
      switch type
        when 'commands' then @addCommands serviceObj[type]
        when 'queries' then @addQueries serviceObj[type]


  addCommand: (commandName, fn) ->
    @_applicationServiceCommands[commandName] = => fn.apply @_di, arguments


  addCommands: (commandObj) ->
    @addCommand commandName, commandFunction for commandName, commandFunction of commandObj


  addQuery: (queryName, fn) ->
    @_applicationServiceQueries[queryName] = => fn.apply @_di, arguments


  addQueries: (queryObj) ->
    @addQuery queryName, queryFunction for queryName, queryFunction of queryObj


  addAggregate: (aggregateName, aggregateDefinitionObj) ->
    @_aggregateDefinitions[aggregateName] = aggregateDefinitionObj


  addReadAggregate: (aggregateName, ReadAggregate) ->
    @_readAggregateDefinitions[aggregateName] = ReadAggregate


  addRepository: (aggregateName, repository) ->
    @_repositories[aggregateName] = repository


  addDomainEventHandler: (eventName, handlerFn) ->
    @_domainEventHandlers[eventName] = [] unless @_domainEventHandlers[eventName]
    @_domainEventHandlers[eventName].push => handlerFn.apply @_di, arguments


  addAdapter: (adapterName, adapterClass) ->
    @_adapters[adapterName] = adapterClass


  addAdapters: (adapterObj) ->
    @addAdapter adapterName, fn for adapterName, fn of adapterObj


  getRepository: (aggregateName) ->
    # return cache if available
    return @_repositoryInstances[aggregateName] if @_repositoryInstances[aggregateName]

    # define name, event store and that we only want to return readaggregates
    repositoryParams =
      aggregateName: aggregateName
      eventStore: @_eventStore
      readAggregate: true

    # check if we have a special read aggregate definition
    if @_readAggregateDefinitions[aggregateName]
      repositoryParams.aggregateDefinition = @_readAggregateDefinitions[aggregateName]

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
