customRemoteBridge = null
eventHandlers = {}

class InMemoryRemoteEndpoint
  constructor: ->
    customRemoteBridge = (rpcRequest) =>
      new Promise (resolve, reject) =>
        @_handleRPCRequest rpcRequest, (error, result) ->
          return reject error if error
          resolve result

  setRPCHandler: (@_handleRPCRequest) ->


  publish: (channel, eventName, payload) ->
    if eventHandlers[channel] and eventHandlers[channel][eventName]
      eventHandlers[channel][eventName].forEach (handler) -> handler(payload)


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


  subscribe: (channel, eventName, handlerFn) ->
    eventHandlers[channel] ?= {}
    eventHandlers[channel][eventName] ?= []
    eventHandlers[channel][eventName].push handlerFn


module.exports.client = new InMemoryRemoteClient