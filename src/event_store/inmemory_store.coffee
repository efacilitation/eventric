class InMemoryStore

  constructor: ->
    @_domainEvents = []

  save: (domainEvent, callback) ->
    @_domainEvents.push domainEvent

    callback? null

  clear: ->
    @_domainEvents = []

  findByAggregateId: (aggregateId, callback) ->
    # cast aggregateId to Int
    aggregateId = parseInt aggregateId

    results = []
    results.push domainEvent for domainEvent in @_domainEvents when domainEvent.aggregate?.id is aggregateId

    callback null, results

  findByAggregateName: (aggregateName, callback) ->
    results = []
    results.push domainEvent for domainEvent in @_domainEvents when domainEvent.aggregate?.name is aggregateName

    callback null, results

  find: (query, callback) ->
    ids = []
    for domainEvent in @_domainEvents
      if Object.keys(query).length == 0
        ids.push domainEvent.aggregate?.id unless domainEvent.aggregate.id in ids
      else
        if query.key of domainEvent.changed.props and domainEvent.changed.props[query.key] is query.value
          ids.push domainEvent.aggregate?.id unless domainEvent.aggregate.id in ids
          break

    callback null, ids

# Singleton
inMemoryStore = new InMemoryStore

module.exports = inMemoryStore