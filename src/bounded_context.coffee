eventric              = require 'eventric'

AggregateRepository   = eventric 'AggregateRepository'
CommandService        = eventric 'CommandService'
DomainEventService    = eventric 'DomainEventService'

class BoundedContext
  aggregates: {}

  readAggregateRepositories: {}
  _readAggregateRepositoriesInstances: {}

  applicationServices: []

  _applicationServiceCommands: {}
  _applicationServiceQueries: {}

  initialize: (EventStore) ->
    @_initializeEventStore EventStore, =>
      @_aggregateRepository  = new AggregateRepository @_eventStore
      @_domainEventService   = new DomainEventService @_eventStore
      @_commandService       = new CommandService @_domainEventService, @_aggregateRepository

      @_initializeAggregates()
      @_initializeReadAggregateRepositories()
      @_initializeApplicationServices()


  _initializeEventStore: (EventStore, next) ->
    if EventStore
      @_eventStore = new EventStore
    else
      MongoDBEventStore = require 'eventric-store-mongodb'
      @_eventStore = new MongoDBEventStore

    @_eventStore.initialize (err) =>
      next()

  _initializeAggregates: ->
    @_aggregateRepository.registerClass aggregateName, aggregateClass for aggregateName, aggregateClass of @aggregates


  _initializeReadAggregateRepositories: ->
    for repositoryName, ReadRepository of @readAggregateRepositories
      @_readAggregateRepositoriesInstances[repositoryName] = new ReadRepository repositoryName, @_eventStore


  _initializeApplicationServices: ->
    for ApplicationService in @applicationServices
      applicationService = new ApplicationService
      for commandName, commandMethodName of applicationService.commands
        # TODO check duplicates, warn and do some logging
        @_applicationServiceCommands[commandName] = ->
          applicationService[commandMethodName].apply applicationService, arguments

      for queryName, queryMethodName of applicationService.queries
        # TODO check duplicates, warn and do some logging
        @_applicationServiceQueries[queryName] = ->
         applicationService[queryMethodName].apply applicationService, arguments


  getReadAggregateRepository: (repositoryName) ->
    @_readAggregateRepositoriesInstances[repositoryName]


  command: (commandName, aggregateId, params) ->
    if @_applicationServiceCommands[commandName]
      @_applicationServiceCommands[commandName] aggregateId, params
    else
      [aggregateName, methodName] = @_splitAggregateAndMethod commandName
      @_commandService.commandAggregate aggregateName, aggregateId, methodName, params


  query: (queryName, aggregateId, params) ->
    if @_applicationServiceQueries[queryName]
      @_applicationServiceQueries[queryName] aggregateId, params
    else
      [aggregateName, methodName] = @_splitAggregateAndMethod queryName
      @getReadAggregateRepository(aggregateName)[methodName] aggregateId, params


  _splitAggregateAndMethod: (input) ->
    input.split ':'


module.exports = BoundedContext