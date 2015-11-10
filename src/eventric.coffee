inmemoryRemote = require 'eventric-remote-inmemory'

GlobalContext = require './global_context'
Remote = require './remote'
Projection = require './projection'
Context = require './context'
inmemoryStore = require './store/inmemory'
uuidGenerator = require './uuid_generator'
logger = require './logger'

class Eventric

  constructor: ->
    @_contexts = {}
    @_params = {}
    @_domainEventHandlers = {}
    @_domainEventHandlersAll = []
    @_storeDefinition = null
    @_remoteEndpoints = []
    @_globalProjectionObjects = []

    @_globalContext = new GlobalContext
    @_projectionService = new Projection @_globalContext
    @addRemoteEndpoint inmemoryRemote.endpoint
    @setStore inmemoryStore, {}


  # TODO: Test
  setStore: (StoreClass, storeOptions = {}) ->
    @_storeDefinition =
      Class: StoreClass
      options: storeOptions


  # TODO: Test
  getStoreDefinition: ->
    @_storeDefinition


  context: (name) ->
    if !name
      throw new Error 'Contexts must have a name'

    context = new Context name

    context.subscribeToAllDomainEvents (domainEvent) =>
      @_delegateDomainEventToRemoteEndpoints domainEvent

    @_contexts[name] = context

    context


  # TODO: Reconsider/Remove when adding EventStore
  initializeGlobalProjections: ->
    Promise.all @_globalProjectionObjects.map (projectionObject) =>
      @_projectionService.initializeInstance projectionObject, {}


  # TODO: Reconsider/Remove when adding EventStore
  addGlobalProjection: (projectionObject) ->
    @_globalProjectionObjects.push projectionObject


  getRegisteredContextNames: ->
    Object.keys @_contexts


  remote: (contextName) ->
    if !contextName
      throw new Error 'Missing context name'
    new Remote contextName


  addRemoteEndpoint: (remoteEndpoint) ->
    @_remoteEndpoints.push remoteEndpoint
    remoteEndpoint.setRPCHandler @_handleRemoteRPCRequest


  generateUuid: ->
    uuidGenerator.generateUuid()


  setLogLevel: (logLevel) ->
    logger.setLogLevel logLevel


  _handleRemoteRPCRequest: (request, callback) =>
    context = @_contexts[request.contextName]
    if not context
      error = new Error "Tried to handle Remote RPC with not registered context #{request.contextName}"
      logger.error error.stack
      callback error, null
      return

    if Remote.ALLOWED_RPC_OPERATIONS.indexOf(request.functionName) is -1
      error = new Error "RPC operation '#{request.functionName}' not allowed"
      logger.error error.stack
      callback error, null
      return

    if request.functionName not of context
      error = new Error "Remote RPC function #{request.functionName} not found on Context #{request.contextName}"
      logger.error error.stack
      callback error, null
      return

    context[request.functionName] request.args...
    .then (result) ->
      callback null, result
    .catch (error) ->
      callback error


  _delegateDomainEventToRemoteEndpoints: (domainEvent) ->
    Promise.all @_remoteEndpoints.map (remoteEndpoint) ->
      publishPromise = Promise.resolve().then ->
        remoteEndpoint.publish domainEvent.context, domainEvent.name, domainEvent
      if domainEvent.aggregate
        publishPromise = publishPromise.then ->
          remoteEndpoint.publish domainEvent.context, domainEvent.name, domainEvent.aggregate.id, domainEvent

      return publishPromise


module.exports = new Eventric
