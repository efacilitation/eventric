eventric = require 'eventric'

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

    @_handle aggregate, 'create'

  handle: (aggregateId, commandName, params) ->
    # get the aggregate from the AggregateRepository
    aggregate = @_aggregateRepository.fetchById aggregateId

    # call the given commandName as method on the aggregate
    # TODO: Error handling if the function is not available
    aggregate[commandName] params

    @_handle aggregate, commandName


  _handle: (aggregate, commandName) ->
    # "trigger" the DomainEvent
    aggregate._domainEvent commandName

    # get the DomainEvents and hand them over to DomainEventService
    domainEvents = aggregate.getDomainEvents()
    DomainEventService.handle domainEvents

    # store a reference to the Aggregate into a local cache
    @aggregateCache[aggregate._id] = aggregate

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