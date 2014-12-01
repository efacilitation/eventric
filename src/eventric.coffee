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
    @ProcessManager  = require './process_manager'
    @Logger          = require './logger'
    @RemoteInMemory  = require './remote/inmemory'
    @StoreInMemory   = require './store/inmemory'

    @log                      = @Logger
    @projectionService        = new @Projection @
    @_contexts                = {}
    @_params                  = {}
    @_processManagerInstances = {}
    @_processManagerService   = @ProcessManager
    @_domainEventHandlers     = {}
    @_domainEventHandlersAll  = []
    @_storeClasses            = {}
    @_remoteEndpoints         = []

    @addRemoteEndpoint 'inmemory', @RemoteInMemory.endpoint
    @addStore 'inmemory', @StoreInMemory
    @set 'default domain events store', 'inmemory'


  ###*
  * @name set
  * @module eventric
  * @description Configure Global parameters
  *
  * @param {String} key Name of the key
  * @param {Mixed} value Value to be set
  ###
  set: (key, value) ->
    @_params[key] = value


  ###*
  * @name get
  * @module eventric
  * @description Get Global configured parameters
  *
  * @param {String} key Name of the Key
  ###
  get: (key) ->
    if not key
      @_params
    else
      @_params[key]


  ###*
  * @name addStore
  * @module eventric
  * @description Add Global Store
  *
  * @param {string} storeName Name of the store
  * @param {Function} StoreClass Class of the store
  * @param {Object} Options to be passed to the store on initialize
  ###
  addStore: (storeName, StoreClass, storeOptions={}) ->
    @_storeClasses[storeName] =
      Class: StoreClass
      options: storeOptions


  ###*
  * @name getStores
  * @module eventric
  * @description Get all Global added Stores
  ###
  getStores: ->
    @_storeClasses


  ###*
  * @name context
  * @module eventric
  * @description Generate a new context instance.
  *
  * @param {String} name Name of the Context
  ###
  context: (name) ->
    if !name
      err = 'Contexts must have a name'
      @log.error err
      throw new Error err
    pubsub = new @PubSub
    context = new @Context name, @
    @mixin context, pubsub

    @_delegateAllDomainEventsToGlobalHandlers context
    @_delegateAllDomainEventsToRemoteEndpoints context

    @_contexts[name] = context

    context


  ###*
  * @name getContext
  * @module eventric
  * @decription Get a Context instance
  ###
  getContext: (name) ->
    @_contexts[name]


  ###*
  * @name remote
  * @module eventric
  * @description Generate a new Remote
  *
  * @param {String} name Name of the Context to remote control
  ###
  remote: (contextName) ->
    if !contextName
      err = 'Missing context name'
      @log.error err
      throw new Error err
    pubsub = new @PubSub
    remote = new @Remote contextName, @
    @mixin remote, pubsub
    remote


  ###*
  * @name addRemoteEndpoint
  * @module eventric
  * @description Add a Global RemoteEndpoint
  *
  * @param {String} remoteName Name of the Remote
  * @param {Object} remoteEndpoint Initialized RemoteEndpoint
  ###
  addRemoteEndpoint: (remoteName, remoteEndpoint) ->
    @_remoteEndpoints.push remoteEndpoint
    remoteEndpoint.setRPCHandler @_handleRemoteRPCRequest


  _handleRemoteRPCRequest: (request, callback) =>
    context = @getContext request.contextName
    if not context
      err = "Tried to handle Remote RPC with not registered context #{request.contextName}"
      @log.error err
      return callback err, null

    if request.method not of context
      err = "Remote RPC method #{request.method} not found on Context #{request.contextName}"
      @log.error err
      return callback err, null

    #middleware(request, user)
    context[request.method] request.params...
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

  ###*
  * @name subscribeToDomainEvent
  * @module eventric
  * @description Global DomainEvent Handlers
  *
  * @param {String} contextName Name of the context or 'all'
  * @param {String} eventName Name of the Event or 'all'
  * @param {Function} eventHandler Function which handles the DomainEvent
  ###
  subscribeToDomainEvent: ([contextName, eventName]..., eventHandler) ->
    contextName ?= 'all'
    eventName ?= 'all'

    if contextName is 'all' and eventName is 'all'
      @_domainEventHandlersAll.push eventHandler
    else
      @_domainEventHandlers[contextName] ?= {}
      @_domainEventHandlers[contextName][eventName] ?= []
      @_domainEventHandlers[contextName][eventName].push eventHandler


  ###*
  * @name getDomainEventHandlers
  * @module eventric
  * @description Get all Global defined DomainEventHandlers
  ###
  getDomainEventHandlers: (contextName, domainEventName) ->
    [].concat (@_domainEventHandlers[contextName]?[domainEventName] ? []),
              (@_domainEventHandlers[contextName]?.all ? []),
              (@_domainEventHandlersAll ? [])


  ###*
  * @name generateUid
  * @module eventric
  * @description Generate a Global Unique ID
  ###
  generateUid: (separator) ->
    # http://stackoverflow.com/a/12223573
    S4 = ->
      (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1
    delim = separator or "-"
    S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4()


  ###*
  * @name addProcessManager
  * @module eventric
  * @description Add a Global Process Manager
  *
  * @param {String} processManagerName Name of the ProcessManager
  * @param {Object} processManagerObject Object containing `initializeWhen` and `class`
  ###
  addProcessManager: (processManagerName, processManagerObj) ->
    @_processManagerService.add processManagerName, processManagerObj, @


  ###*
  * @name nextTick
  * @module eventric
  * @description Execute a function after the nextTick
  *
  * @param {Function} next Function to be executed after the nextTick
  ###
  nextTick: (next) ->
    nextTick = process?.nextTick ? setTimeout
    nextTick ->
      next()


  ###*
  * @name defaults
  * @module eventric
  * @description Apply default options to a given option object
  *
  * @param {Object} options Object which will eventually contain the options
  * @param {Object} optionDefaults Object containing default options
  ###
  defaults: (options, optionDefaults) ->
    allKeys = [].concat (Object.keys options), (Object.keys optionDefaults)
    for key in allKeys when !options[key] and optionDefaults[key]
      options[key] = optionDefaults[key]
    options


  ###*
  * @name eachSeries
  * @module eventric
  * @description Execute every function in the given Array in series, then the given callback
  *
  * @param {Array} arr Array containing functions
  * @param {Function} iterator Function to be called
  * @param {Function} callback Callback to be called after the function series
  ###
  eachSeries: (arr, iterator, callback) ->
    # MIT https://github.com/jb55/async-each-series
    callback = callback or ->

    return callback()  if not Array.isArray(arr) or not arr.length
    completed = 0
    iterate = ->
      iterator arr[completed], (err) ->
        if err
          callback err
          callback = ->
        else
          ++completed
          if completed >= arr.length
            callback()
          else
            iterate()
        return
      return

    iterate()


  mixin: (destination, source) ->
    for prop of source
      destination[prop] = source[prop]


module.exports = Eventric
