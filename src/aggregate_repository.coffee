eventric = require 'eventric'

Repository    = eventric 'Repository'
AggregateRoot = eventric 'AggregateRoot'

class AggregateRepository extends Repository

  constructor: (_adapter, @_AggregateClass) ->
    @_AggregateClass ?= AggregateRoot
    super _adapter

  findById: (id) ->
    # find all domainEvents matching the given aggregateId
    domainEvents = @_findDomainEventsByAggregateId id

    # construct the Aggregate
    aggregate = new @_AggregateClass

    # apply the domainevents on the ReadAggregate
    aggregate._applyChanges domainEvent._changed for domainEvent in domainEvents
    aggregate.id = id

    # return the readAggregate
    aggregate


module.exports = AggregateRepository