class DomainEvent
  constructor: (params) ->
    @name = params.name
    @timestamp = new Date().getTime()
    @aggregate = params.aggregate


  getAggregateChanges: (type) ->
    switch type
      when 'props', 'entities', 'collections'
        @aggregate.changed[type]
      else @aggregate.changed


  getAggregateName: ->
    @aggregate.name


  getAggregateId: ->
    @aggregate.id


  getTimestamp: ->
    @timestamp


  getName: ->
    @name


module.exports = DomainEvent