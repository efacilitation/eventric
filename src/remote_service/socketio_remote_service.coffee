class SocketIORemoteService

  constructor: (@_io_client) ->
    @_callbacks = {}

    @_io_client.on 'RPC_Response', (response) =>
      if not response.rpcId
        throw new Error 'Missing rpcId in RPC Response'

      if response.rpcId not of @_callbacks
        throw new Error "No callback registered for id #{response.rpcId}"

      @_callbacks[response.rpcId] response.data
      delete @_callbacks[response.rpcId]


  rpc: (payload, callback) ->
    rpcId = @_generateUid()
    payload.rpcId = rpcId
    @_callbacks[rpcId] = (data) ->
      callback null, data

    @_io_client.emit 'RPC_Request', payload


  _generateUid: (separator) ->
    # http://stackoverflow.com/a/12223573
    S4 = ->
      (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1
    delim = separator or "-"
    S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4()


module.exports = SocketIORemoteService