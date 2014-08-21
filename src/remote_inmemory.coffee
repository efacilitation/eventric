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


  publish: (context, [domainEventName, aggregateId]..., payload) ->
    fullEventName = getFullEventName context, domainEventName, aggregateId
    if eventHandlers[fullEventName]
      eventHandlers[fullEventName].forEach (handler) -> handler(payload)


module.exports.endpoint = new InMemoryRemoteEndpoint


class InMemoryRemoteClient
  rpc: (rpcRequest, callback) ->
    if not customRemoteBridge
      throw new Error 'No Remote Endpoint available for in memory client'
    customRemoteBridge rpcRequest
    .then (result) ->
      callback null, result
    .catch (error) ->
      callback error


  subscribe: (context, [domainEventName, aggregateId]..., handlerFn) ->
    fullEventName = getFullEventName context, domainEventName, aggregateId
    eventHandlers[fullEventName] ?= []
    eventHandlers[fullEventName].push handlerFn


  unsubscribe: (context, [domainEventName, aggregateId]..., handlerFn) ->
    fullEventName = getFullEventName context, domainEventName, aggregateId
    eventHandlers[fullEventName] =
      eventHandlers[fullEventName].filter (registeredHandler) -> registeredHandler isnt handlerFn


module.exports.client = new InMemoryRemoteClient

getFullEventName = (context, domainEventName, aggregateId) ->
  fullEventName = context
  if domainEventName
    fullEventName += "/#{domainEventName}"
  if aggregateId
    fullEventName += "/#{aggregateId}"
  fullEventName
