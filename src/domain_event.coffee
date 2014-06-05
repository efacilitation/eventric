class DomainEvent
  constructor: (params) ->
    @name = params.name
    @timestamp = new Date().getTime()
    @aggregate = params.aggregate


  getAggregateChanges: ->
    @aggregate.changed


  getAggregateName: ->
    @aggregate.name


  getAggregateId: ->
    @aggregate.id


  getTimestamp: ->
    @timestamp


  getName: ->
    @name


module.exports = DomainEvent