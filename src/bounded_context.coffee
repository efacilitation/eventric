eventric = require 'eventric'

_                       = eventric.require 'HelperUnderscore'
AggregateService        = eventric.require 'AggregateService'
AggregateRoot           = eventric.require 'AggregateRoot'
AggregateRepository     = eventric.require 'AggregateRepository'
ReadAggregateRoot       = eventric.require 'ReadAggregateRoot'
ReadAggregateRepository = eventric.require 'ReadAggregateRepository'
DomainEventService      = eventric.require 'DomainEventService'

class BoundedContext
  _di: {}
  _params: {}
  aggregates: {}
  readAggregates: {}
  adapters: {}

  readAggregateRepositories: {}
  _readAggregateRepositoriesInstances: {}

  applicationServices: []

  _applicationServiceCommands: {}
  _applicationServiceQueries: {}
  _domainEventHandlers: {}
  _adapterInstances: {}


  initialize: (callback) ->
    @_initializeEventStore =>
      @_aggregateRepository  = new AggregateRepository @_eventStore
      @_domainEventService   = new DomainEventService @_eventStore
      @_aggregateService     = new AggregateService @_domainEventService, @_aggregateRepository

      @_di =
        aggregate: @_aggregateService
        repository: => @getRepository.apply @, arguments
        adapter: => @getAdapter.apply @, arguments

      @_initializeRepositories()
      @_initializeAggregates()
      @_initializeDomainEventHandlers()
      @_initializeAdapters()

      callback? null


  set: (key, value) ->
    @_params[key] = value


  addCommand: (commandName, fn) ->
    @_applicationServiceCommands[commandName] = => fn.apply @_di, arguments


  addCommands: (commandObj) ->
    @addCommand commandName, commandFunction for commandName, commandFunction of commandObj


  addQuery: (queryName, fn) ->
    @_applicationServiceQueries[queryName] = => fn.apply @_di, arguments


  addQueries: (queryObj) ->
    @addQuery queryName, queryFunction for queryName, queryFunction of queryObj


  addAggregate: (aggregateName, aggregateDefinitionObj) ->
    @aggregates[aggregateName] = aggregateDefinitionObj


  addReadAggregate: (aggregateName, ReadAggregate) ->
    @readAggregates[aggregateName] = ReadAggregate


  addRepository: (aggregateName, readAggregateRepository) ->
    @readAggregateRepositories[aggregateName] = readAggregateRepository


  addDomainEventHandler: (eventName, handlerFn) ->
    @_domainEventHandlers[eventName] = [] unless @_domainEventHandlers[eventName]
    @_domainEventHandlers[eventName].push => handlerFn.apply @_di, arguments


  addAdapter: (adapterName, adapterClass) ->
    @adapters[adapterName] = adapterClass


  addAdapters: (adapterObj) ->
    @addAdapter adapterName, fn for adapterName, fn of adapterObj


  _initializeEventStore: (next) ->
    if @_params.store
      @_eventStore = @_params.store
      next()
    else
      # TODO: refactor to use a pseudo-store (which just logs that it wont save anything)
      @_eventStore = require 'eventric-store-mongodb'
      @_eventStore.initialize (err) =>
        next()


  _initializeAggregates: ->
    for aggregateName, aggregateDefinition of @aggregates
      @_aggregateRepository.registerAggregateDefinition aggregateName, aggregateDefinition

      # add default repository if not already defined
      if !@_readAggregateRepositoriesInstances[aggregateName]
        @_readAggregateRepositoriesInstances[aggregateName] = new ReadAggregateRepository aggregateName, @_eventStore

      # register read aggregate to repository
      if @readAggregates[aggregateName]
        @_readAggregateRepositoriesInstances[aggregateName].registerReadAggregateClass aggregateName, @readAggregates[aggregateName]


  _initializeRepositories: ->
    for aggregateName, readRepositoryObj of @readAggregateRepositories
      readRepository = new ReadAggregateRepository aggregateName, @_eventStore
      _.extend readRepository, readRepositoryObj
      @_readAggregateRepositoriesInstances[aggregateName] = readRepository


  _initializeDomainEventHandlers: ->
    for domainEventName, fnArray of @_domainEventHandlers
      for fn in fnArray
        @onDomainEvent domainEventName, fn


  _initializeAdapters: ->
    for adapterName, adapterClass of @adapters
      adapter = new adapterClass
      adapter.initialize?()
      @_adapterInstances[adapterName] = adapter


  getRepository: (aggregateName) ->
    @_readAggregateRepositoriesInstances[aggregateName]


  getAdapter: (adapterName) ->
    @_adapterInstances[adapterName]


  command: (command, callback = ->) ->
    if @_applicationServiceCommands[command.name]
      @_applicationServiceCommands[command.name] command.params, callback
    else
      errorMessage = "Given command #{command.name} not registered on bounded context"
      callback new Error errorMessage


  query: (query, callback = ->) ->
    if @_applicationServiceQueries[query.name]
      @_applicationServiceQueries[query.name] query.params, callback
    else
      errorMessage = "Given query #{query.name} not registered on bounded context"
      callback new Error errorMessage


  onDomainEvent: (eventName, eventHandler) ->
    @_domainEventService.on eventName, eventHandler


module.exports = BoundedContext
