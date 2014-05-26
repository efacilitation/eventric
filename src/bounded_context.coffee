eventric              = require 'eventric'

AggregateRepository   = eventric.require 'AggregateRepository'
CommandService        = eventric.require 'CommandService'
DomainEventService    = eventric.require 'DomainEventService'

class BoundedContext
  _params: {}
  aggregates: {}

  readAggregateRepositories: {}
  _readAggregateRepositoriesInstances: {}

  applicationServices: []

  _applicationServiceCommands: {}
  _applicationServiceQueries: {}

  initialize: (callback) ->
    @_initializeEventStore =>
      @_aggregateRepository  = new AggregateRepository @_eventStore
      @_domainEventService   = new DomainEventService @_eventStore
      @_commandService       = new CommandService @_domainEventService, @_aggregateRepository

      @_initializeAggregates()
      @_initializeReadAggregateRepositories()
      @_initializeApplicationServices()

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


  getReadAggregateRepository: (repositoryName) ->
    @_readAggregateRepositoriesInstances[repositoryName]


  # TODO: emit error if command is not registered and not valid for default call
  command: (command, callback) ->
    if @_applicationServiceCommands[command.name]
      @_applicationServiceCommands[command.name] command.params, callback
    else
      [aggregateName, methodName] = @_splitAggregateAndMethod command.name
      @_commandService.commandAggregate aggregateName, command.id, methodName, command.params, callback


  # TODO: emit error if query is not registered and not valid for default call
  query: (query, callback) ->
    if @_applicationServiceQueries[query.name]
      @_applicationServiceQueries[query.name] query.params, callback
    else
      [aggregateName, methodName] = @_splitAggregateAndMethod query.name
      # TODO: Refactor the bounded context API to be consistent or remove default mapping of commands/queries
      if methodName is 'findById'
        @getReadAggregateRepository(aggregateName)[methodName] query.id, callback
      else
        @getReadAggregateRepository(aggregateName)[methodName] query.id, query.params, callback


  _splitAggregateAndMethod: (input) ->
    input.split ':'


  onDomainEvent: (eventName, eventHandler) ->
    @_domainEventService.on eventName, eventHandler


module.exports = BoundedContext