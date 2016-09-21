class Remote

  @ALLOWED_RPC_OPERATIONS: [
    'command'
    'query'
    'findDomainEventsByName'
    'findDomainEventsByNameAndAggregateId'
  ]

  constructor: (@_contextName) ->
    Projection = require 'eventric/projection'
    inmemoryRemote = require 'eventric-remote-inmemory'

    @_params = {}
    @_handlerFunctions = {}
    @_projectionService = new Projection @
    @setClient inmemoryRemote.client

    @_exposeRpcOperationsAsMemberFunctions()


  _exposeRpcOperationsAsMemberFunctions: ->
    Remote.ALLOWED_RPC_OPERATIONS.forEach (rpcOperation) =>
      @[rpcOperation] = =>
        @_rpc rpcOperation, arguments


  subscribeToAllDomainEvents: (handlerFn) ->
    @_client.subscribe @_contextName, handlerFn


  subscribeToDomainEvent: (domainEventName, handlerFn) ->
    @_client.subscribe @_contextName, domainEventName, handlerFn


  subscribeToDomainEventWithAggregateId: (domainEventName, aggregateId, handlerFn) ->
    @_client.subscribe @_contextName, domainEventName, aggregateId, handlerFn


  unsubscribeFromDomainEvent: (subscriberId) ->
    @_client.unsubscribe subscriberId


  _rpc: (functionName, args) ->
    @_client.rpc
      contextName: @_contextName
      functionName: functionName
      args: Array.prototype.slice.call args


  setClient: (client) ->
    @_client = client
    @


  initializeProjection: (projectionObject, params) ->
    return @_projectionService.initializeInstance projectionObject, params


  destroyProjectionInstance: (projectionId) ->
    @_projectionService.destroyInstance projectionId, @


module.exports = Remote
