eventric        = require 'eventric'
AggregateEntity = eventric 'AggregateEntity'

class AggregateRoot extends AggregateEntity

  constructor: ->
    @_domainEvents = []
    super

  create: ->
    # TODO this should be an unique id
    @id = 1

  generateDomainEvent: (eventName, params={}) ->

    params.includeAggregateChanges = true unless params.includeAggregateChanges is false

    event =
      name: eventName
      aggregate: @_metaData()

    if params.includeAggregateChanges
      event.aggregate.changed = @_changes()
      @_clearChanges()

    # TODO return error if DomainEvent is empty (no changes, no payload)

    @_domainEvents.push event


  getDomainEvents: ->
    @_domainEvents


module.exports = AggregateRoot