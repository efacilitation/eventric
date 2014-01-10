eventric = require 'eventric'

DomainEventService = eventric 'DomainEventService'

class CommandService

  constructor: (@_aggregateRepository) ->
    @aggregateCache = {}

  createAggregate: (Aggregate, params) ->

    # create Aggregate
    aggregate = new Aggregate
    aggregate.create()

    # apply given params
    aggregate[key] = value for key, value of params

    @_handle 'create', aggregate

  commandAggregate: (aggregateId, commandName, params) ->
    # get the aggregate from the AggregateRepository
    aggregate = @_aggregateRepository.findById aggregateId

    # call the given commandName as method on the aggregate
    # TODO: Error handling if the function is not available
    aggregate[commandName] params

    @_handle commandName, aggregate


  _handle: (commandName, aggregate) ->
    # generate the DomainEvent
    aggregate.generateDomainEvent commandName

    # get the DomainEvents and hand them over to DomainEventService
    domainEvents = aggregate.getDomainEvents()
    DomainEventService.handle domainEvents

    # TODO save DomainEvents, this needs some refactoring..
    @_aggregateRepository._saveDomainEvents domainEvents

    # store a reference to the Aggregate into a local cache
    # TODO support garbage-collector-callback which gets called in intervals to check if we can drop the cache-entry
    @aggregateCache[aggregate.id] = aggregate

    # return the aggregateId
    aggregate.id


module.exports = CommandService