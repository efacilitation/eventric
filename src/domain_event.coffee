class DomainEvent
  constructor: (params) ->
    @id             = params.id
    @name           = params.name
    @payload        = params.payload
    @aggregate      = params.aggregate
    @microContext = params.microContext
    @timestamp      = new Date().getTime()


module.exports = DomainEvent