class Eventric

  constructor: ->
    @PubSub          = require './pub_sub'
    @EventBus        = require './event_bus'
    @Remote          = require './remote'
    @Context         = require './context'
    @DomainEvent     = require './domain_event'
    @Aggregate       = require './aggregate'
    @Repository      = require './repository'
    @Projection      = require './projection'
    @Logger          = require './logger'
    @RemoteInMemory  = require './remote/inmemory'
    @StoreInMemory   = require './store/inmemory'
    @GlobalContext   = require './global_context'

    @log                      = @Logger
    @_contexts                = {}
    @_params                  = {}
    @_domainEventHandlers     = {}
    @_domainEventHandlersAll  = []
    @_storeClasses            = {}
    @_remoteEndpoints         = []
    @_globalProjectionClasses = []

    @_globalContext = new @GlobalContext @
    @_projectionService = new @Projection @, @_globalContext

    @addRemoteEndpoint 'inmemory', @RemoteInMemory.endpoint
    @addStore 'inmemory', @StoreInMemory
    @set 'default domain events store', 'inmemory'


  set: (key, value) ->
    @_params[key] = value


  get: (key) ->
    if not key
      @_params
    else
      @_params[key]


  addStore: (storeName, StoreClass, storeOptions = {}) ->
    @_storeClasses[storeName] =
      Class: StoreClass
      options: storeOptions


  getStores: ->
    @_storeClasses


  context: (name) ->
    if !name
      error = 'Contexts must have a name'
      @log.error error
      throw new Error error

    context = new @Context name, @

    @_delegateAllDomainEventsToGlobalHandlers context
    @_delegateAllDomainEventsToRemoteEndpoints context

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
      err = 'Missing context name'
      @log.error err
      throw new Error err
    new @Remote contextName, @


  addRemoteEndpoint: (remoteName, remoteEndpoint) ->
    @_remoteEndpoints.push remoteEndpoint
    remoteEndpoint.setRPCHandler @_handleRemoteRPCRequest


  _handleRemoteRPCRequest: (request, callback) =>
    context = @getContext request.contextName
    if not context
      error = new Error "Tried to handle Remote RPC with not registered context #{request.contextName}"
      @log.error error.stack
      return callback error, null

    if @Remote.ALLOWED_RPC_OPERATIONS.indexOf(request.functionName) is -1
      error = new Error "RPC operation '#{request.functionName}' not allowed"
      @log.error error.stack
      return callback error, null

    if request.functionName not of context
      error = new Error "Remote RPC function #{request.functionName} not found on Context #{request.contextName}"
      @log.error error.stack
      return callback error, null

    context[request.functionName] request.args...
    .then (result) ->
      callback null, result
    .catch (error) ->
      callback error


  _delegateAllDomainEventsToGlobalHandlers: (context) ->
    context.subscribeToAllDomainEvents (domainEvent) =>
      eventHandlers = @getDomainEventHandlers context.name, domainEvent.name
      for eventHandler in eventHandlers
        eventHandler domainEvent


  _delegateAllDomainEventsToRemoteEndpoints: (context) ->
    context.subscribeToAllDomainEvents (domainEvent) =>
      @_remoteEndpoints.forEach (remoteEndpoint) ->
        remoteEndpoint.publish context.name, domainEvent.name, domainEvent
        if domainEvent.aggregate
          remoteEndpoint.publish context.name, domainEvent.name, domainEvent.aggregate.id, domainEvent


  subscribeToDomainEvent: ([contextName, eventName]..., eventHandler) ->
    contextName ?= 'all'
    eventName ?= 'all'

    if contextName is 'all' and eventName is 'all'
      @_domainEventHandlersAll.push eventHandler
    else
      @_domainEventHandlers[contextName] ?= {}
      @_domainEventHandlers[contextName][eventName] ?= []
      @_domainEventHandlers[contextName][eventName].push eventHandler


  getDomainEventHandlers: (contextName, domainEventName) ->
    [].concat (@_domainEventHandlers[contextName]?[domainEventName] ? []),
              (@_domainEventHandlers[contextName]?.all ? []),
              (@_domainEventHandlersAll ? [])


  generateUid: (separator) ->
    # http://stackoverflow.com/a/12223573
    S4 = ->
      (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1
    delim = separator or "-"
    S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4()


  # TODO: Use existing npm module
  defaults: (options, optionDefaults) ->
    allKeys = [].concat (Object.keys options), (Object.keys optionDefaults)
    for key in allKeys when !options[key] and optionDefaults[key]
      options[key] = optionDefaults[key]
    options


  # TODO: Use existing npm module
  mixin: (destination, source) ->
    for prop of source
      destination[prop] = source[prop]


module.exports = Eventric
