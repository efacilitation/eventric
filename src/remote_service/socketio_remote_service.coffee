class SocketIORemoteService

  constructor: (@_io_client) ->

  rpc: (payload, callback) ->
    @_io_client.emit 'RPC_Request', payload
    callback null

module.exports = SocketIORemoteService
