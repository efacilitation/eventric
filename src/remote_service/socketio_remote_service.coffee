class SocketIORemoteService

  constructor: (@_io_client) ->

  rpc: (payload) ->
    @_io_client.emit 'RPC_Request', payload

module.exports = SocketIORemoteService
