# polyfill promises
promise = require('es6-promise')
if (typeof module isnt 'undefined') and (typeof process isnt 'undefined')
  global.Promise = promise.Promise


class Eventric

  constructor: ->
    @_contexts = {}
    @_params = {}
    @_domainEventHandlers = {}
    @_domainEventHandlersAll = []
    @_processManagerService = require 'eventric/src/process_manager'
    @_processManagerInstances = {}
    @_storeClasses = {}
    @_remoteEndpoints = []
    @log = require 'eventric/src/logger'
    @addRemoteEndpoint 'inmemory', (require 'eventric/src/remote/inmemory').endpoint
    @addStore 'inmemory', require 'eventric/src/store_inmemory'
    @set 'default domain events store', 'inmemory'


  ###*
  * @name set
  *
  * @module Eventric
  ###
  set: (key, value) ->
    @_params[key] = value


  ###*
  * @name get
  *
  * @module Eventric
  ###
  get: (key) ->
    if not key
      @_params
    else
      @_params[key]


  ###*
  * @name addStore
  *
  * @module Eventric
  ###
  addStore: (storeName, StoreClass, storeOptions={}) ->
    @_storeClasses[storeName] =
      Class: StoreClass
      options: storeOptions


  ###*
  * @name getStores
  *
  * @module Eventric
  ###
  getStores: ->
    @_storeClasses


  ###*
  * @name context
  *
  * @module Eventric
  *
  * @description Get a new context instance.
  *
  * @param {String} name Name of the context
  ###
  context: (name) ->
    if !name
      err = 'Contexts must have a name'
      @log.error err
      throw new Error err
    Context = require 'eventric/src/context'
    context = new Context name

    @_delegateAllDomainEventsToGlobalHandlers context
    @_delegateAllDomainEventsToRemoteEndpoints context

    @_contexts[name] = context

    context


  ###*
  * @name getContext
  *
  * @module Eventric
  ###
  getContext: (name) ->
    @_contexts[name]


  ###*
  * @name remote
  *
  * @module Eventric
  ###
  remote: (contextName) ->
    if !contextName
      err = 'Missing context name'
      @log.error err
      throw new Error err
    Remote = require 'eventric/src/remote'
    remote = new Remote contextName
    remote


  ###*
  * @name addRemoteEndpoint
  *
  * @module Eventric
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
  *
  * @module Eventric
  *
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
  *
  * @module Eventric
  ###
  getDomainEventHandlers: (contextName, domainEventName) ->
    [].concat (@_domainEventHandlers[contextName]?[domainEventName] ? []),
              (@_domainEventHandlers[contextName]?.all ? []),
              (@_domainEventHandlersAll ? [])


  ###*
  * @name generateUid
  *
  * @module Eventric
  ###
  generateUid: (separator) ->
    # http://stackoverflow.com/a/12223573
    S4 = ->
      (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1
    delim = separator or "-"
    S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4()


  ###*
  *
  * @description Global Process Manager
  *
  * @module Eventric
  *
  * @param {String} processManagerName Name of the ProcessManager
  * @param {Object} processManagerObject Object containing `initializeWhen` and `class`
  ###
  addProcessManager: (processManagerName, processManagerObj) ->
    @_processManagerService.add processManagerName, processManagerObj, @


  ###*
  * @name nextTick
  *
  * @module Eventric
  ###
  nextTick: (next) ->
    nextTick = process?.nextTick ? setTimeout
    nextTick ->
      next()


  ###*
  * @name defaults
  *
  * @module Eventric
  ###
  defaults: (options, optionDefaults) ->
    allKeys = [].concat (Object.keys options), (Object.keys optionDefaults)
    for key in allKeys when !options[key] and optionDefaults[key]
      options[key] = optionDefaults[key]
    options


  ###*
  * @name eachSeries
  *
  * @module Eventric
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


module.exports = new Eventric