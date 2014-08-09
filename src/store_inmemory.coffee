class InMemoryStore

  _domainEvents: {}
  _projections: {}

  initialize: (@_contextName, [options]..., callback) ->
    @_domainEventsCollectionName = "#{@_contextName}.domain_events"
    @_projectionCollectionName   = "#{@_contextName}.projections"

    @_domainEvents[@_domainEventsCollectionName] = []
    callback()


  saveDomainEvent: (domainEvent, callback) ->
    @_domainEvents[@_domainEventsCollectionName].push doc
    callback null, doc


  findAllDomainEvents: (callback) ->
    events = []
    callback null, @_domainEvents[@_domainEventsCollectionName]


  findDomainEventsByName: (name, callback) ->
    @_domainEvents[@_domainEventsCollectionName].filter (event) ->
      event.name == name


  findDomainEventsByAggregateId: (aggregateId, callback) ->
    @_domainEvents[@_domainEventsCollectionName].filter (event) ->
      event.aggregate?.id == aggregateId


  findDomainEventsByAggregateName: (aggregateName, callback) ->
    @_domainEvents[@_domainEventsCollectionName].filter (event) ->
      event.aggregate?.name == aggregateName


  getProjectionStore: (projectionName, callback) ->
    @_projections[@_projectionCollectionName] ?= {}
    @_projections[@_projectionCollectionName][projectionName] ?= {}
    callback null, @_projections[projectionName]


  clearProjectionStore: (projectionName, callback) ->
    @_projections[@_projectionCollectionName] ?= {}
    @_projections[@_projectionCollectionName][projectionName] ?= {}
    delete @_projections[@_projectionCollectionName][projectionName]
    callback null, null


module.exports = InMemoryStore