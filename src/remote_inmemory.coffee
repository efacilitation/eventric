PubSub = require './pub_sub'

customRemoteBridge = null
pubSub = new PubSub

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
    pubSub.publish fullEventName, payload, ->


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
    pubSub.subscribe fullEventName, handlerFn


  unsubscribe: (subscriberId) ->
    pubSub.unsubscribe subscriberId


module.exports.client = new InMemoryRemoteClient

getFullEventName = (context, domainEventName, aggregateId) ->
  fullEventName = context
  if domainEventName
    fullEventName += "/#{domainEventName}"
  if aggregateId
    fullEventName += "/#{aggregateId}"
  fullEventName
