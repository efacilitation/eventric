remoteInmemory = require 'eventric-remote-inmemory'

GlobalContext = require './global_context'
Remote = require './remote'
Projection = require './projection'
Context = require './context'
StoreInMemory = require './store/inmemory'
uidGenerator = require './uid_generator'

class Eventric

  constructor: ->
    @_contexts = {}
    @_params = {}
    @_domainEventHandlers = {}
    @_domainEventHandlersAll = []
    @_storeDefintion = null
    @_remoteEndpoints = []
    @_globalProjectionClasses = []

    @_globalContext = new GlobalContext
    @_projectionService = new Projection @_globalContext
    @setRemoteEndpoint remoteInmemory.endpoint
    @setStore StoreInMemory, {}


  setStore: (StoreClass, storeOptions = {}) ->
    @_storeDefintion =
      Class: StoreClass
      options: storeOptions


  context: (name) ->
    if !name
      error = 'Contexts must have a name'
      @log.error error
      throw new Error error

    context = new Context name, @_storeDefintion

    @_delegateAllDomainEventsToRemoteEndpoint context

    @_contexts[name] = context

    context


  # TODO: Reconsider/Remove when adding EventStore
  initializeGlobalProjections: ->
    Promise.all @_globalProjectionClasses.map (GlobalProjectionClass) =>
      @_projectionService.initializeInstance '', new GlobalProjectionClass, {}


  # TODO: Reconsider/Remove when adding EventStore
  addGlobalProjection: (ProjectionClass) ->
    @_globalProjectionClasses.push ProjectionClass


  getRegisteredContextNames: ->
    Object.keys @_contexts


  getContext: (name) ->
    @_contexts[name]


  remote: (contextName) ->
    if !contextName
      error = 'Missing context name'
      @log.error error
      throw new Error error
    new Remote contextName


  setRemoteEndpoint: (remoteEndpoint) ->
    @_remoteEndpoint = remoteEndpoint
    @_remoteEndpoint.setRPCHandler @_handleRemoteRPCRequest


  generateUid: ->
    uidGenerator.generateUid()


  _handleRemoteRPCRequest: (request, callback) =>
    context = @getContext request.contextName
    if not context
      error = new Error "Tried to handle Remote RPC with not registered context #{request.contextName}"
      @log.error error.stack
      callback error, null
      return

    if Remote.ALLOWED_RPC_OPERATIONS.indexOf(request.functionName) is -1
      error = new Error "RPC operation '#{request.functionName}' not allowed"
      callback error, null
      return

    if request.functionName not of context
      error = new Error "Remote RPC function #{request.functionName} not found on Context #{request.contextName}"
      @log.error error.stack
      callback error, null
      return

    context[request.functionName] request.args...
    .then (result) ->
      callback null, result
    .catch (error) ->
      callback error


  _delegateAllDomainEventsToRemoteEndpoint: (context) ->
    context.subscribeToAllDomainEvents (domainEvent) =>
      @_remoteEndpoint.publish context.name, domainEvent.name, domainEvent
      if domainEvent.aggregate
        @_remoteEndpoint.publish context.name, domainEvent.name, domainEvent.aggregate.id, domainEvent


module.exports = new Eventric
