class DomainEvent
  constructor: (params) ->
    @name = params.name
    @timestamp = new Date().getTime()
    @aggregate = params.aggregate


  getChangedAggregateProps: ->
    @aggregate.changed.props


  getTimestamp: ->
    @timestamp


module.exports = DomainEvent