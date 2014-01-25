class RemoteService

  constructor: (@_adapter) ->

  rpc: (payload) ->
    @_adapter.rpc payload

module.exports = RemoteService