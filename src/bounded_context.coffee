eventric              = require 'eventric'

_                     = eventric.require 'HelperUnderscore'
AggregateRoot         = eventric.require 'AggregateRoot'
AggregateRepository   = eventric.require 'AggregateRepository'
CommandService        = eventric.require 'CommandService'
DomainEventService    = eventric.require 'DomainEventService'

class BoundedContext
  _di: {}
  _params: {}
  aggregates: {}

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

      @_initializeAggregates()
      @_initializeReadAggregateRepositories()
      @_initializeApplicationServices()
      @_initializeDomainEventHandler()

      callback? null


  set: (key, value) ->
    @_params[key] = value


  add: (type, key, value) ->
    switch type
      when 'aggregate'
        @aggregates[key] = value
      when 'aggregates'
        for name, obj of key
          @aggregates[name] = obj
      when 'repository'
        @readAggregateRepositories[key] = value
      when 'repositories'
        for name, obj of key
          @readAggregateRepositories[name] = obj
      when 'application'
         @applicationServices.push key
      when 'applications'
        for obj in key
          @applicationServices.push obj


  addCommand: (commandName, fn) ->
    @_applicationServiceCommands[commandName] = => fn.apply @_di, arguments


  addQuery: (queryName, fn) ->
    @_applicationServiceQueries[queryName] = => fn.apply @_di, arguments


  addAggregate: (aggregateName, aggregateObj) ->
    @aggregates[aggregateName] = aggregateObj


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
      @_aggregateRepository.registerClass aggregateName, aggregateClass


  _initializeReadAggregateRepositories: ->
    for repositoryName, ReadRepository of @readAggregateRepositories
      @_readAggregateRepositoriesInstances[repositoryName] = new ReadRepository repositoryName, @_eventStore


  _initializeApplicationServices: ->
    for applicationService in @applicationServices
      applicationService.commandService = @_commandService
      applicationService.getReadAggregateRepository = => @getReadAggregateRepository.apply @, arguments
      applicationService.onDomainEvent = => @onDomainEvent.apply @, arguments

      for commandName, commandMethodName of applicationService.commands
        # TODO: check duplicates, warn and do some logging
        do (commandName, commandMethodName, applicationService) =>
          @_applicationServiceCommands[commandName] = ->
            applicationService[commandMethodName].apply applicationService, arguments

      for queryName, queryMethodName of applicationService.queries
        # TODO: check duplicates, warn and do some logging
        do (queryName, queryMethodName, applicationService) =>
          @_applicationServiceQueries[queryName] = ->
            applicationService[queryMethodName].apply applicationService, arguments

      applicationService.initialize?()


  _initializeDomainEventHandler: ->
    @onDomainEvent domainEventName, fn for domainEventName, fn of @_domainEventHandlers


  getReadAggregateRepository: (repositoryName) ->
    @_readAggregateRepositoriesInstances[repositoryName]


  command: (command, callback = ->) ->
    if @_applicationServiceCommands[command.name]
      @_applicationServiceCommands[command.name] command.params, callback
    else
      errorMessage = "Given command #{command.name} not registered on bounded context"
      callback new Error errorMessage


  query: (query, callback) ->
    if @_applicationServiceQueries[query.name]
      @_applicationServiceQueries[query.name] query.params, callback
    else
      errorMessage = "Given query #{query.name} not registered on bounded context"
      callback new Error errorMessage


  onDomainEvent: (eventName, eventHandler) ->
    @_domainEventService.on eventName, eventHandler


module.exports = BoundedContext