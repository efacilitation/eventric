eventric = require 'eventric'

_                         = eventric 'HelperUnderscore'
AggregateEntity           = eventric 'AggregateEntity'
AggregateEntityCollection = eventric 'AggregateEntityCollection'
MixinSetGet               = eventric 'MixinSetGet'
DomainEvent               = eventric 'DomainEvent'

class AggregateRoot extends AggregateEntity

  constructor: ->
    @_domainEvents = []
    super


  generateDomainEvent: (eventName, params={}) ->

    params.includeAggregateChanges = true unless params.includeAggregateChanges is false

    eventParams =
      name: eventName
      aggregate: @getMetaData()

    if params.includeAggregateChanges
      changes = @getChanges()
      if Object.keys(changes).length > 0
        eventParams.aggregate.changed = changes

    domainEvent = new DomainEvent eventParams
    @_domainEvents.push domainEvent


  getDomainEvents: ->
    @_domainEvents


  getSnapshot: ->
    eventParams =
      name: '_snapshot'
      aggregate: @getMetaData()

    eventParams.aggregate.changed = @getChanges()

    domainEvent = new DomainEvent eventParams
    domainEvent


  registerEntityCollection: (collectionName, entityName, entityClass) ->
    @[collectionName] = new AggregateEntityCollection
    @registerEntityClass entityName, entityClass


  addEntityToCollection: (entity, collectionName) ->
    @[collectionName].add entity


module.exports = AggregateRoot
