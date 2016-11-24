Context = require './context'
Remote = require './remote'
Projection = require './projection'
uuidGenerator = require './uuid_generator'

remoteContextHash = {}

class Eventric

  constructor: ->
    @_logger = require './logger'

    GlobalContext = require './global_context'
    inmemoryRemote = require 'eventric-remote-inmemory'
    InmemoryStore = require 'eventric-store-inmemory'

    @_contexts = {}
    @_params = {}
    @_domainEventHandlers = {}
    @_domainEventHandlersAll = []
    @_storeDefinition = null
    @_remoteEndpoints = []
    @_globalProjections = []

    @_globalContext = new GlobalContext
    @addRemoteEndpoint inmemoryRemote.endpoint
    @setStore InmemoryStore, {}


  setLogger: (logger) ->
    @_logger = logger


  getLogger: ->
    return @_logger


  setLogLevel: (logLevel) ->
    @_logger.setLogLevel logLevel


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
    if not @_projectionService
      @_projectionService = new Projection @_globalContext

    startOfInitialization = new Date
    @_logger.debug 'eventric global projections initializing'

    initializeGlobalProjectionsPromise = Promise.resolve()
    @_globalProjections.forEach (globalProjection) =>
      initializeGlobalProjectionsPromise = initializeGlobalProjectionsPromise.then =>
        @_projectionService.initializeInstance globalProjection, {}

    initializeGlobalProjectionsPromise
    .then =>
      endOfInitialization = new Date
      durationOfInitialization = endOfInitialization - startOfInitialization
      @_logger.debug "eventric global projections initialized after #{durationOfInitialization}ms"

    return initializeGlobalProjectionsPromise


  # TODO: Reconsider/Remove when adding EventStore
  addGlobalProjection: (projectionObject) ->
    @_globalProjections.push projectionObject


  getRegisteredContextNames: ->
    Object.keys @_contexts


  setDefaultRemoteClient: (remoteClient) ->
    @_defaultRemoteClient = remoteClient


  remoteContext: (contextName) ->
    if !contextName
      throw new Error 'Missing context name'

    return remoteContextHash[contextName] if remoteContextHash[contextName]

    remote = remoteContextHash[contextName] = new Remote contextName

    if @_defaultRemoteClient
      remote.setClient @_defaultRemoteClient

    return remote


  addRemoteEndpoint: (remoteEndpoint) ->
    @_remoteEndpoints.push remoteEndpoint
    remoteEndpoint.setRPCHandler @_handleRemoteRPCRequest


  generateUuid: ->
    uuidGenerator.generateUuid()


  _handleRemoteRPCRequest: (request, callback) =>
    context = @_contexts[request.contextName]
    if not context
      error = new Error "Tried to handle Remote RPC with not registered context #{request.contextName}"
      @_logger.error error, '\n', error.stack
      callback error, null
      return

    if Remote.ALLOWED_RPC_OPERATIONS.indexOf(request.functionName) is -1
      error = new Error "RPC operation '#{request.functionName}' not allowed"
      @_logger.error error, '\n', error.stack
      callback error, null
      return

    if request.functionName not of context
      error = new Error "Remote RPC function #{request.functionName} not found on Context #{request.contextName}"
      @_logger.error  error, '\n', error.stack
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
