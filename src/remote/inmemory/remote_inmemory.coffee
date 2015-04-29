PubSub = require '../../pub_sub'

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


  publish: (contextName, [domainEventName, aggregateId]..., payload) ->
    fullEventName = getFullEventName contextName, domainEventName, aggregateId
    pubSub.publish fullEventName, payload, ->


module.exports.endpoint = new InMemoryRemoteEndpoint


class InMemoryRemoteClient

  rpc: (rpcRequest) ->
    if not customRemoteBridge
      throw new Error 'No Remote Endpoint available for in memory client'
    customRemoteBridge rpcRequest


  subscribe: (contextName, [domainEventName, aggregateId]..., handlerFn) ->
    fullEventName = getFullEventName contextName, domainEventName, aggregateId
    pubSub.subscribe fullEventName, handlerFn


  unsubscribe: (subscriberId) ->
    pubSub.unsubscribe subscriberId


module.exports.client = new InMemoryRemoteClient

getFullEventName = (contextName, domainEventName, aggregateId) ->
  fullEventName = contextName
  if domainEventName
    fullEventName += "/#{domainEventName}"
  if aggregateId
    fullEventName += "/#{aggregateId}"
  fullEventName
