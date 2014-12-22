STORE_SUPPORTS = ['domain_events', 'projections']


class InMemoryStore

  _domainEvents: {}
  _projections: {}

  initialize: (@_context, [options]...) ->  new Promise (resolve, reject) =>
    @_domainEventsCollectionName = "#{@_context.name}.DomainEvents"
    @_projectionCollectionName   = "#{@_context.name}.Projections"

    @_domainEvents[@_domainEventsCollectionName] = []
    resolve()


  ###*
  * @name saveDomainEvent
  *
  * @module InMemoryStore
  ###
  saveDomainEvent: (domainEvent, callback) ->
    @_domainEvents[@_domainEventsCollectionName].push domainEvent
    callback null, domainEvent


  ###*
  * @name findAllDomainEvents
  *
  * @module InMemoryStore
  ###
  findAllDomainEvents: (callback) ->
    callback null, @_domainEvents[@_domainEventsCollectionName]

  ###*
  * @name findDomainEventsByName
  *
  * @module InMemoryStore
  ###
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


  ###*
  * @name findDomainEventsByNameAndAggregateId
  *
  * @module InMemoryStore
  ###
  findDomainEventsByNameAndAggregateId: (name, aggregateId, callback) ->
    if name instanceof Array
      checkNameFn = (eventName) ->
        (name.indexOf eventName) > -1
    else
      checkNameFn = (eventName) ->
        eventName == name

    if aggregateId instanceof Array
      checkAggregateIdFn = (eventAggregateId) ->
        (aggregateId.indexOf eventAggregateId) > -1
    else
      checkAggregateIdFn = (eventAggregateId) ->
        eventAggregateId == aggregateId

    events = @_domainEvents[@_domainEventsCollectionName].filter (event) ->
      (checkNameFn event.name) and (checkAggregateIdFn event.aggregate?.id)
    callback null, events


  ###*
  * @name findDomainEventsByAggregateId
  *
  * @module InMemoryStore
  ###
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


  ###*
  * @name findDomainEventsByAggregateName
  *
  * @module InMemoryStore
  ###
  findDomainEventsByAggregateName: (aggregateName, callback) ->
    if aggregateName instanceof Array
      checkFn = (eventAggregateName) ->
        (aggregateName.indexOf eventAggregateName) > -1
    else
      checkFn = (eventAggregateName) ->
        eventAggregateName == aggregateName

    events = @_domainEvents[@_domainEventsCollectionName].filter (event) ->
      checkFn event.aggregate?.name
    callback null, events


  ###*
  * @name getProjectionStore
  *
  * @module InMemoryStore
  ###
  getProjectionStore: (projectionName) -> new Promise (resolve, reject) =>
    @_projections[@_projectionCollectionName] ?= {}
    @_projections[@_projectionCollectionName][projectionName] ?= {}
    resolve @_projections[@_projectionCollectionName][projectionName]


  ###*
  * @name clearProjectionStore
  *
  * @module InMemoryStore
  ###
  clearProjectionStore: (projectionName) -> new Promise (resolve, reject) =>
    @_projections[@_projectionCollectionName] ?= {}
    @_projections[@_projectionCollectionName][projectionName] ?= {}
    delete @_projections[@_projectionCollectionName][projectionName]
    resolve()


  ###*
  * @name checkSupport
  *
  * @module InMemoryStore
  ###
  checkSupport: (check) ->
    (STORE_SUPPORTS.indexOf check) > -1


module.exports = InMemoryStore