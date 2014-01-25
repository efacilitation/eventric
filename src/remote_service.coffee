class RemoteService

  constructor: (@_adapter) ->

  rpc: ->
    @_adapter.rpc()

module.exports = RemoteService