eventric              = require 'eventric'

AggregateRepository   = eventric 'AggregateRepository'
CommandService        = eventric 'CommandService'
DomainEventService    = eventric 'DomainEventService'

class BoundedContext
  aggregates: {}
  readAggregateRepositories: {}

  _readAggregateRepositoriesInstances: {}

  initialize: ->
    # TODO provide an event store
    @_eventStore = 'provideMe'
    @aggregateRepository  = new AggregateRepository @_eventStore
    @domainEventService   = new DomainEventService @_eventStore
    @commandService       = new CommandService @domainEventService, @aggregateRepository
    @_initializeAggregates()
    @_initializeReadAggregateRepositories()


  _initializeAggregates: ->
    @aggregateRepository.registerClass aggregateName, aggregateClass for aggregateName, aggregateClass of @aggregates


  _initializeReadAggregateRepositories: ->
    for repositoryName, repositoryClass of @readAggregateRepositories
      @_readAggregateRepositoriesInstances[repositoryName] = new repositoryClass 'foobar', @_eventStore


  getReadAggregateRepository: (repositoryName) ->
    @_readAggregateRepositoriesInstances[repositoryName]


  command: (command, aggregateId, params) ->
    [aggregateName, methodName] = command.split ':'
    @commandService.commandAggregate aggregateName, aggregateId, methodName, params


module.exports = BoundedContext