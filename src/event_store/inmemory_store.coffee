class InMemoryStore

  constructor: ->
    @_domainEvents = []

  save: (domainEvent, callback) ->
    @_domainEvents.push domainEvent

    console.log 'SAVED DOMAINEVENT', domainEvent.name
    if domainEvent.aggregate?.changed
      console.log '-> AGGREGATED CHANGED', domainEvent.aggregate.changed

    if domainEvent.aggregate.changed.collections.checkins?
      console.log '--> CHECKINS', domainEvent.aggregate.changed.collections.checkins


    console.log 'ALL DOMAINEVENTS', @_domainEvents

    callback? null

  clear: ->
    @_domainEvents = []

  findByAggregateId: (aggregateId, callback) ->
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