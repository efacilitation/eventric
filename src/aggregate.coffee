eventric = require 'eventric'

_               = eventric.require 'HelperUnderscore'
DomainEvent     = eventric.require 'DomainEvent'
AggregateEntity = eventric.require 'AggregateEntity'

class Aggregate extends AggregateEntity

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


module.exports = Aggregate
