# polyfill promises
require './helper/promise'

moduleDefinition =
  MicroContext: './micro_context'
  Aggregate: './aggregate'
  DomainEvent: './domain_event'
  EventBus: './event_bus'
  Repository: './repository'

  RemoteService: './remote_service'
  RemoteMicroContext: './remote_micro_context'

  HelperAsync: './helper/async'
  HelperEvents: './helper/events'
  HelperUnderscore: './helper/underscore'
  HelperClone: './helper/clone'


module.exports =
  _params: {}
  _domainEventHandlers: {}
  _domainEventHandlersAll: []
  _processManagerInstances: {}

  require: (required) ->
    path = moduleDefinition[required] ? required

    try
      require path
    catch e
      console.log e
      throw e


  set: (key, value) ->
    @_params[key] = value


  get: (key) ->
    @_params[key]


  ###*
  *
  * @description Get a new MicroContext instance.
  *
  * @param {String} name Name of the MicroContext
  ###
  microContext: (name) ->
    if !name
      throw new Error 'MicroContexts must have a name'
    MicroContext = @require 'MicroContext'
    microContext = new MicroContext name

    @_delegateAllDomainEventsToGlobalHandlers microContext

    microContext


  context: ->
    @microContext arguments...


  _delegateAllDomainEventsToGlobalHandlers: (microContext) ->
    microContext.addDomainEventHandler 'DomainEvent', (domainEvent) =>
      eventHandlers = @getDomainEventHandlers microContext.name, domainEvent.name
      for eventHandler in eventHandlers
        eventHandler domainEvent


  ###*
  *
  * @description Global DomainEvent Handlers
  *
  * @param {String} microContextName Name of the MicroContext or 'all'
  * @param {String} eventName Name of the Event or 'all'
  * @param {Function} eventHandler Function which handles the DomainEvent
  ###
  addDomainEventHandler: ([microContextName, eventName]..., eventHandler) ->
    microContextName ?= 'all'
    eventName ?= 'all'

    if microContextName is 'all' and eventName is 'all'
      @_domainEventHandlersAll.push eventHandler
    else
      @_domainEventHandlers[microContextName] ?= {}
      @_domainEventHandlers[microContextName][eventName] ?= []
      @_domainEventHandlers[microContextName][eventName].push eventHandler


  getDomainEventHandlers: (microContextName, domainEventName) ->
    [].concat (@_domainEventHandlers[microContextName]?[domainEventName] ? []),
              (@_domainEventHandlers[microContextName]?.all ? []),
              (@_domainEventHandlersAll ? [])


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
  * @param {String} processManagerName Name of the ProcessManager
  * @param {Object} processManagerObject Object containing `initializeWhen` and `class`
  ###
  addProcessManager: (processManagerName, processManagerObj) ->
    for microContextName, domainEventName of processManagerObj.initializeWhen
      @addDomainEventHandler microContextName, domainEventName, (domainEvent) =>
        # TODO: make sure we dont spawn twice
        @_spawnProcessManager processManagerName, processManagerObj.class, microContextName, domainEvent


  _spawnProcessManager: (processManagerName, ProcessManagerClass, microContextName, domainEvent) ->
    processManagerId = @generateUid()
    processManager = new ProcessManagerClass

    processManager.$endProcess = =>
      @_endProcessManager processManagerName, processManagerId

    handleContextDomainEventNames = []
    for key, value of processManager
      if (key.indexOf 'handle') is 0 and (typeof value is 'function')
        handleContextDomainEventNames.push key


    @_subscribeProcessManagerToDomainEvents processManager, handleContextDomainEventNames

    processManager.initialize domainEvent

    @_processManagerInstances[processManagerName] ?= {}
    @_processManagerInstances[processManagerName][processManagerId] ?= {}
    @_processManagerInstances[processManagerName][processManagerId] = processManager


  _endProcessManager: (processManagerName, processManagerId) ->
    delete @_processManagerInstances[processManagerName][processManagerId]


  _subscribeProcessManagerToDomainEvents: (processManager, handleContextDomainEventNames) ->
    @addDomainEventHandler (domainEvent) =>
      for handleContextDomainEventName in handleContextDomainEventNames
        if "handle#{domainEvent.microContext}#{domainEvent.name}" == handleContextDomainEventName
          @_applyDomainEventToProcessManager handleContextDomainEventName, domainEvent, processManager


  _applyDomainEventToProcessManager: (handleContextDomainEventName, domainEvent, processManager) ->
    if !processManager[handleContextDomainEventName]
      err = new Error "Tried to apply DomainEvent '#{domainEventName}' to Projection without a matching handle method"

    else
      processManager[handleContextDomainEventName] domainEvent