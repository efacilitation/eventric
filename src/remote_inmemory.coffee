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


  publish: (eventName, payload) ->
    if eventHandlers[eventName]
      eventHandlers[eventName].forEach (handler) -> handler(payload)


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


  subscribe: (eventName, handlerFn) ->
    eventHandlers[eventName] ?= []
    eventHandlers[eventName].push handlerFn


  unsubscribe: (eventName, handlerFn) ->
    eventHandlers[eventName] = eventHandlers[eventName].filter (registeredHandler) -> registeredHandler isnt handlerFn


module.exports.client = new InMemoryRemoteClient