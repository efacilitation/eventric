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
    if name instanceof Array
      checkFn = (eventName) ->
        (name.indexOf eventName) > -1
    else
      checkFn = (eventName) ->
        eventName == name

    events = @_domainEvents[@_domainEventsCollectionName].filter (event) ->
      checkFn event.name
    callback null, events


  findDomainEventsByAggregateId: (aggregateId, callback) ->
    if aggregateId instanceof Array
      checkFn = (eventAggregateId) ->
        (aggregateId.indexOf eventAggregateId) > -1
    else
      checkFn = (eventAggregateId) ->
        eventAggregateId == aggregateId

    events = @_domainEvents[@_domainEventsCollectionName].filter (event) ->
      checkFn event.aggregate?.id
    callback null, events


  findDomainEventsByAggregateName: (aggregateName, callback) ->
    if aggregateName instanceof Array
      checkFn = (eventAggregateName) ->
        (aggregateId.indexOf eventAggregateName) > -1
    else
      checkFn = (eventAggregateName) ->
        eventAggregateName == aggregateId

    events = @_domainEvents[@_domainEventsCollectionName].filter (event) ->
      checkFn event.aggregate?.name
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