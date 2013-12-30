eventric = require 'eventric'

ReadAggregateRoot       = eventric 'ReadAggregateRoot'
ReadAggregateRepository = eventric 'ReadAggregateRepository'
DomainEventService      = eventric 'DomainEventService'
Repository              = eventric 'Repository'

class CommandService

  constructor: (@_aggregateRepository, @_readAggregateRepository) ->
    @aggregateCache = {}

  create: (Aggregate) ->
    # create Aggregate
    aggregate = new Aggregate
    aggregate.create()

    # store a reference to the Aggregate into a local cache
    @aggregateCache[aggregate._id] = aggregate

    # "trigger" the DomainEvent
    aggregate._domainEvent 'create'

    # get the DomainEvent and hand it over to DomainEventService
    domainEvents = aggregate.getDomainEvents()
    DomainEventService.handle domainEvents

    # get the ReadAggregate
    readAggregate = @_readAggregateRepository.findById aggregate._id

    # return ReadAggregate
    readAggregate

  handle: (aggregateId, commandName, params) ->
    aggregate = @_aggregateRepository.fetchById aggregateId
    # TODO: Error handling if the function is not available
    aggregate[commandName] params
    domainEvents = aggregate.getDomainEvents()
    DomainEventService.handle domainEvents

    # get the ReadAggregate
    readAggregate = @_readAggregateRepository.findById aggregate._id

    # return ReadAggregate
    readAggregate



  fetch: (modelId, name, params) ->
    #TODO: implement!

  remove: (modelId, name, params) ->
    #TODO: implement!

  destroy: (modelId, name, params) ->
    #TODO: implement!

module.exports = CommandService