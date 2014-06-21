class DomainEvent
  constructor: (params) ->
    @id        = params.id
    @name      = params.name
    @context   = params.context
    @payload   = params.payload
    @aggregate = params.aggregate
    @timestamp = new Date().getTime()


module.exports = DomainEvent