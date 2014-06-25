class DomainEvent
  constructor: (params) ->
    @id        = params.id
    @name      = params.name
    @payload   = params.payload
    @aggregate = params.aggregate
    @timestamp = new Date().getTime()


module.exports = DomainEvent