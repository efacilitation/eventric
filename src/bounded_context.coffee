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
        repository: => @getRepository.apply @, arguments


      @_initializeRepositories()
      @_initializeAggregates()
      @_initializeDomainEventHandler()

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


  addAggregate: (aggregateName, Aggregate) ->
    @aggregates[aggregateName] = Aggregate


  addReadAggregate: (aggregateName, ReadAggregate) ->
    @readAggregates[aggregateName] = ReadAggregate


  addRepository: (aggregateName, readAggregateRepository) ->
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


  _initializeRepositories: ->
    for aggregateName, readRepositoryObj of @readAggregateRepositories
      readRepository = new ReadAggregateRepository aggregateName, @_eventStore
      _.extend readRepository, readRepositoryObj
      @_readAggregateRepositoriesInstances[aggregateName] = readRepository


  _initializeDomainEventHandler: ->
    @onDomainEvent domainEventName, fn for domainEventName, fn of @_domainEventHandlers


  getRepository: (aggregateName) ->
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
