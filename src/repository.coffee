eventric = require 'eventric'

Entity = eventric 'AggregateEntity'

class Repository

  constructor: (@_adapter) ->

  _findDomainEventsByAggregateId: (aggregateId) ->
    @_adapter._findDomainEventsByAggregateId aggregateId

  _findAggregateIdsByDomainEventCriteria: (criteria) ->
    @_adapter._findAggregateIdsByDomainEventCriteria criteria


module.exports = Repository
