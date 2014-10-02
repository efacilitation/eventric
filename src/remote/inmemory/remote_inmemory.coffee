PubSub = require 'eventric/src/pub_sub'

customRemoteBridge = null
pubSub = new PubSub

class InMemoryRemoteEndpoint
  constructor: ->
    customRemoteBridge = (rpcRequest) =>
      new Promise (resolve, reject) =>
        @_handleRPCRequest rpcRequest, (error, result) ->
          return reject error if error
          resolve result

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
  publish: (context, [domainEventName, aggregateId]..., payload) ->
    fullEventName = getFullEventName context, domainEventName, aggregateId
    pubSub.publish fullEventName, payload, ->


module.exports.endpoint = new InMemoryRemoteEndpoint


class InMemoryRemoteClient

  ###*
  * @name rpc
  *
  * @module InMemoryRemoteClient
  ###
  rpc: (rpcRequest, callback) ->
    if not customRemoteBridge
      throw new Error 'No Remote Endpoint available for in memory client'
    customRemoteBridge rpcRequest
    .then (result) ->
      callback null, result
    .catch (error) ->
      callback error


  ###*
  * @name subscribe
  *
  * @module InMemoryRemoteClient
  ###
  subscribe: (context, [domainEventName, aggregateId]..., handlerFn) ->
    fullEventName = getFullEventName context, domainEventName, aggregateId
    pubSub.subscribe fullEventName, handlerFn


  ###*
  * @name unsubscribe
  *
  * @module InMemoryRemoteClient
  ###
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
