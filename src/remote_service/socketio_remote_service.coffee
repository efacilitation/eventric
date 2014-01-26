class SocketIORemoteService

  constructor: (@_io_client) ->

  rpc: (payload, callback) ->
    @_io_client.on 'RPC_Response', (data) ->
      callback data

    @_io_client.emit 'RPC_Request', payload


module.exports = SocketIORemoteService
