class InMemoryAdapter

  constructor: ->
    @_domainEvents = []

  _saveDomainEvents: (domainEvents) ->
    @_domainEvents.push domainEvent for domainEvent in domainEvents

  _findDomainEventsByAggregateId: (aggregateId) ->
    domainEvent for domainEvent in @_domainEvents when domainEvent.metaData?.id is aggregateId

  _findAggregateIdsByDomainEventCriteria: (query) ->
    # dirrrttyyy

    ids = []
    for domainEvent in @_domainEvents
      if Object.keys(query).length == 0
        ids.push domainEvent.metaData?.id unless domainEvent.metaData.id in ids
      else
        for key, value of query
          if key of domainEvent._changed.props and domainEvent._changed.props[key] == value
            ids.push domainEvent.metaData?.id unless domainEvent.metaData.id in ids
            break

    ids

# Singleton
inMemoryAdapter = new InMemoryAdapter

module.exports = inMemoryAdapter