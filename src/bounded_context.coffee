eventric = require 'eventric'

_                       = eventric.require 'HelperUnderscore'
AggregateRoot           = eventric.require 'AggregateRoot'
AggregateRepository     = eventric.require 'AggregateRepository'
ReadAggregateRoot       = eventric.require 'ReadAggregateRoot'
ReadAggregateRepository = eventric.require 'ReadAggregateRepository'
CommandService          = eventric.require 'CommandService'
DomainEventService      = eventric.require 'DomainEventService'

class BoundedContext
  _di: {}
  _params: {}
  aggregates: {}
  readAggregates: {}

  readAggregateRepositories: {}
  _readAggregateRepositoriesInstances: {}

  applicationServices: []

  _applicationServiceCommands: {}
  _applicationServiceQueries: {}
  _domainEventHandlers: {}


  initialize: (callback) ->
    @_initializeEventStore =>
      @_aggregateRepository  = new AggregateRepository @_eventStore
      @_domainEventService   = new DomainEventService @_eventStore
      @_commandService       = new CommandService @_domainEventService, @_aggregateRepository

      @_di =
        aggregate:
          create: @_commandService.createAggregate
          command: @_commandService.commandAggregate
        repository: => @getReadAggregateRepository.apply @, arguments


      @_initializeReadAggregateRepositories()
      @_initializeAggregates()
      @_initializeDomainEventHandler()

      callback? null


  set: (key, value) ->
    @_params[key] = value


  addCommand: (commandName, fn) ->
    @_applicationServiceCommands[commandName] = => fn.apply @_di, arguments


  addQuery: (queryName, fn) ->
    @_applicationServiceQueries[queryName] = => fn.apply @_di, arguments


  addAggregate: (aggregateName, aggregateObj) ->
    @aggregates[aggregateName] = aggregateObj


  addReadAggregate: (aggregateName, readAggregateObj) ->
    @readAggregates[aggregateName] = readAggregateObj


  addReadAggregateRepository: (aggregateName, readAggregateRepository) ->
    @readAggregateRepositories[aggregateName] = readAggregateRepository


  addDomainEventHandler: (eventName, fn) ->
    @_domainEventHandlers[eventName] = => fn.apply @_di, arguments


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
    for aggregateName, aggregateClass of @aggregates
      @_aggregateRepository.registerAggregateObj aggregateName, aggregateClass

      # add default repository if not already defined
      if !@_readAggregateRepositoriesInstances[aggregateName]
        @_readAggregateRepositoriesInstances[aggregateName] = new ReadAggregateRepository aggregateName, @_eventStore

      # add default read aggregate if not already defined
      if !@readAggregates[aggregateName]
        @readAggregates[aggregateName] = ReadAggregateRoot

      # register read aggregate to repository
      @_readAggregateRepositoriesInstances[aggregateName].registerReadAggregateObj aggregateName, @readAggregates[aggregateName]


  _initializeReadAggregateRepositories: ->
    for aggregateName, ReadRepository of @readAggregateRepositories
      @_readAggregateRepositoriesInstances[aggregateName] = new ReadRepository aggregateName, @_eventStore


  _initializeDomainEventHandler: ->
    @onDomainEvent domainEventName, fn for domainEventName, fn of @_domainEventHandlers


  getReadAggregateRepository: (aggregateName) ->
    @_readAggregateRepositoriesInstances[aggregateName]


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