remoteInmemory = require 'eventric-remote-inmemory'

logger = require 'eventric/logger'
Projection = require 'eventric/projection'

class Remote

  @ALLOWED_RPC_OPERATIONS: [
    'command'
    'query'
    'findDomainEventsByName'
    'findDomainEventsByNameAndAggregateId'
  ]

  constructor: (@_contextName) ->
    @name = @_contextName

    @_params = {}
    @_projectionClasses = {}
    @_projectionInstances = {}
    @_handlerFunctions = {}
    @projectionService = new Projection @
    @setClient remoteInmemory.client

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


  addProjection: (projectionName, projectionClass) ->
    @_projectionClasses[projectionName] = projectionClass
    @


  initializeProjection: (projectionObject, params) ->
    @projectionService.initializeInstance '', projectionObject, params


  initializeProjectionInstance: (projectionName, params) ->
    if not @_projectionClasses[projectionName]
      return Promise.reject new Error "Given projection #{projectionName} not registered on remote"

    @projectionService.initializeInstance projectionName, @_projectionClasses[projectionName], params


  getProjectionInstance: (projectionId) ->
    @projectionService.getInstance projectionId


  destroyProjectionInstance: (projectionId) ->
    @projectionService.destroyInstance projectionId, @


module.exports = Remote
