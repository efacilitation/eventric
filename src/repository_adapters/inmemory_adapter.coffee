class InMemoryAdapter

  constructor: ->
    @_domainEvents = []

  saveDomainEvents: (domainEvents) ->
    @_domainEvents.push domainEvent for domainEvent in domainEvents

  findDomainEventsByAggregateId: (aggregateId) ->
    domainEvent for domainEvent in @_domainEvents when domainEvent.metaData?.id is aggregateId

  findAggregateIdsByDomainEventCriteria: (query) ->
    domainEvent.metaData?.id for domainEvent in @_domainEvents

# Singleton
inMemoryAdapter = new InMemoryAdapter

module.exports = inMemoryAdapter