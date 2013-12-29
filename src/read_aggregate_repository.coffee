class ReadAggregateRepository
  constructor: (@_adapter, @_ReadAggregateClass) ->

  findById: (id) ->
    new @_ReadAggregateClass @_findAggregateDataById id

  _findAggregateDataById: (id) ->
    @_adapter.findById id

module.exports = ReadAggregateRepository