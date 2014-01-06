eventric = require 'eventric'

Entity = eventric 'AggregateEntity'

class Repository

  constructor: (@_adapter) ->

  # TODO this could actually just be a mixin of the adapter, right?

  _findDomainEventsByAggregateId: (aggregateId) ->
    @_adapter._findDomainEventsByAggregateId aggregateId

  _findAggregateIdsByDomainEventCriteria: (criteria) ->
    @_adapter._findAggregateIdsByDomainEventCriteria criteria

  _saveDomainEvents: (domainEvents) ->
    @_adapter._saveDomainEvents domainEvents


module.exports = Repository
