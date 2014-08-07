customRemoteBridge = null

class InMemoryRemoteEndpoint
  constructor: ->
    customRemoteBridge = (rpcRequest) =>
      new Promise (resolve, reject) =>
        @_handleRPCRequest rpcRequest, (error, result) ->
          return reject error if error
          resolve result

  setRPCHandler: (@_handleRPCRequest) ->


module.exports.endpoint = new InMemoryRemoteEndpoint


class InMemoryRemoteClient
  rpc: (rpcRequest, callback) ->
    if not customRemoteBridge
      throw new Error 'No Remote Endpoint available for inmemory Client'
    customRemoteBridge rpcRequest
    .then (result) ->
      callback null, result
    .catch (error) ->
      callback error

module.exports.client = new InMemoryRemoteClient