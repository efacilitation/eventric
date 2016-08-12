class DomainEvent

  constructor: (params) ->
    @id             = params.id
    @name           = params.name
    @payload        = params.payload
    @aggregate      = params.aggregate
    @context        = params.context
    @timestamp      = new Date().getTime()


module.exports = DomainEvent
