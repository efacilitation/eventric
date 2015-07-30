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

    @InMemoryRemote = require './inmemory'

    @_params = {}
    @_clients = {}
    @_projectionClasses = {}
    @_projectionInstances = {}
    @_handlerFunctions = {}
    @projectionService = new Projection @
    @addClient 'inmemory', @InMemoryRemote.client
    @set 'default client', 'inmemory'

    @_exposeRpcOperationsAsMemberFunctions()


  _exposeRpcOperationsAsMemberFunctions: ->
    Remote.ALLOWED_RPC_OPERATIONS.forEach (rpcOperation) =>
      @[rpcOperation] = =>
        @_rpc rpcOperation, arguments


  set: (key, value) ->
    @_params[key] = value
    @


  get: (key) ->
    @_params[key]


  subscribeToAllDomainEvents: (handlerFn) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.subscribe @_contextName, handlerFn


  subscribeToDomainEvent: (domainEventName, handlerFn) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.subscribe @_contextName, domainEventName, handlerFn


  subscribeToDomainEventWithAggregateId: (domainEventName, aggregateId, handlerFn) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.subscribe @_contextName, domainEventName, aggregateId, handlerFn


  unsubscribeFromDomainEvent: (subscriberId) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.unsubscribe subscriberId


  _rpc: (functionName, args) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.rpc
      contextName: @_contextName
      functionName: functionName
      args: Array.prototype.slice.call args


  addClient: (clientName, client) ->
    @_clients[clientName] = client
    @


  getClient: (clientName) ->
    @_clients[clientName]


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
