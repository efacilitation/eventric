STORE_SUPPORTS = ['domain_events', 'projections']


class InMemoryStore

  _domainEvents: {}
  _projections: {}

  initialize: (@_contextName, [options]..., callback) ->
    @_domainEventsCollectionName = "#{@_contextName}.DomainEvents"
    @_projectionCollectionName   = "#{@_contextName}.Projections"

    @_domainEvents[@_domainEventsCollectionName] = []
    callback()


  saveDomainEvent: (domainEvent, callback) ->
    @_domainEvents[@_domainEventsCollectionName].push domainEvent
    callback null, domainEvent


  findAllDomainEvents: (callback) ->
    events = []
    callback null, @_domainEvents[@_domainEventsCollectionName]


  findDomainEventsByName: (name, callback) ->
    events = @_domainEvents[@_domainEventsCollectionName].filter (event) ->
      event.name == name
    callback null, events


  findDomainEventsByNames: (names, callback) ->
    events = @_domainEvents[@_domainEventsCollectionName].filter (event) ->
      (names.indexOf event.name) > -1
    callback null, events


  findDomainEventsByAggregateId: (aggregateId, callback) ->
    events = @_domainEvents[@_domainEventsCollectionName].filter (event) ->
      event.aggregate?.id == aggregateId
    callback null, events


  findDomainEventsByAggregateIds: (aggregateIds, callback) ->
    events = @_domainEvents[@_domainEventsCollectionName].filter (event) ->
      (aggregateIds.indexOf event.aggregate?.id) > -1
    callback null, events


  findDomainEventsByAggregateName: (aggregateName, callback) ->
    events = @_domainEvents[@_domainEventsCollectionName].filter (event) ->
      event.aggregate?.name == aggregateName
    callback null, events


  findDomainEventsByAggregateNames: (aggregateNames, callback) ->
    events = @_domainEvents[@_domainEventsCollectionName].filter (event) ->
      (aggregateNames.indexOf event.aggregate?.name) > -1
    callback null, events


  getProjectionStore: (projectionName, callback) ->
    @_projections[@_projectionCollectionName] ?= {}
    @_projections[@_projectionCollectionName][projectionName] ?= {}
    callback null, @_projections[@_projectionCollectionName][projectionName]


  clearProjectionStore: (projectionName, callback) ->
    @_projections[@_projectionCollectionName] ?= {}
    @_projections[@_projectionCollectionName][projectionName] ?= {}
    delete @_projections[@_projectionCollectionName][projectionName]
    callback null, null


  checkSupport: (check) ->
    (STORE_SUPPORTS.indexOf check) > -1


module.exports = InMemoryStore