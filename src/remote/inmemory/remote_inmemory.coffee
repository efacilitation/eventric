PubSub = require '../../pub_sub'

customRemoteBridge = null
pubSub = new PubSub

class InMemoryRemoteEndpoint
  constructor: ->
    customRemoteBridge = (rpcRequest) =>
      @_handleRPCRequest rpcRequest

  ###*
  * @name setRPCHandler
  *
  * @module InMemoryRemoteEndpoint
  ###
  setRPCHandler: (@_handleRPCRequest) ->


  ###*
  * @name publish
  *
  * @module InMemoryRemoteEndpoint
  ###
  publish: (contextName, [domainEventName, aggregateId]..., payload) ->
    fullEventName = getFullEventName contextName, domainEventName, aggregateId
    pubSub.publish fullEventName, payload, ->


module.exports.endpoint = new InMemoryRemoteEndpoint


class InMemoryRemoteClient

  ###*
  * @name rpc
  *
  * @module InMemoryRemoteClient
  ###
  rpc: (rpcRequest) ->
    if not customRemoteBridge
      throw new Error 'No Remote Endpoint available for in memory client'
    customRemoteBridge rpcRequest


  ###*
  * @name subscribe
  *
  * @module InMemoryRemoteClient
  ###
  subscribe: (contextName, [domainEventName, aggregateId]..., handlerFn) ->
    fullEventName = getFullEventName contextName, domainEventName, aggregateId
    pubSub.subscribe fullEventName, handlerFn


  ###*
  * @name unsubscribe
  *
  * @module InMemoryRemoteClient
  ###
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
