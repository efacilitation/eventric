eventric = require 'eventric'

_                         = eventric 'HelperUnderscore'
AggregateEntity           = eventric 'AggregateEntity'
AggregateEntityCollection = eventric 'AggregateEntityCollection'
MixinSnapshot             = eventric 'MixinSnapshot'
MixinSetGet               = eventric 'MixinSetGet'
DomainEvent               = eventric 'DomainEvent'

class AggregateRoot extends AggregateEntity

  _.extend @prototype, MixinSnapshot::

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


  registerEntityCollection: (collectionName, entityName, entityClass) ->
    @_set collectionName, new AggregateEntityCollection
    @registerEntityClass entityName, entityClass


  addEntityToCollection: (entity, collectionName) ->
    # get collection
    collection = @_get collectionName

    # add entity to collection
    collection.add entity


module.exports = AggregateRoot
