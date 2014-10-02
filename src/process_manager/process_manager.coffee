class ProcessManagerService

  constructor: ->
    @_processManagerInstances = {}

  ###*
  * @name add
  *
  * @module ProcessManagerService
  *
  * @description Process Manager
  *
  * @param {String} processManagerName Name of the ProcessManager
  * @param {Object} processManagerObject Object containing `initializeWhen` and `class`
  ###
  add: (processManagerName, processManagerObj, index) ->
    for contextName, domainEventNames of processManagerObj.initializeWhen
      for domainEventName in domainEventNames
        index.subscribeToDomainEvent contextName, domainEventName, (domainEvent) =>
          # TODO: make sure we dont spawn twice
          @_spawnProcessManager processManagerName, processManagerObj.class, contextName, domainEvent, index


  _spawnProcessManager: (processManagerName, ProcessManagerClass, contextName, domainEvent, index) ->
    processManagerId = index.generateUid()
    processManager = new ProcessManagerClass

    processManager.$endProcess = =>
      @_endProcessManager processManagerName, processManagerId

    handleContextDomainEventNames = []
    for key, value of processManager
      if (key.indexOf 'from') is 0 and (typeof value is 'function')
        handleContextDomainEventNames.push key

    @_subscribeProcessManagerToDomainEvents processManager, handleContextDomainEventNames, index

    processManager.initialize domainEvent


    @_processManagerInstances[processManagerName] ?= {}
    @_processManagerInstances[processManagerName][processManagerId] ?= {}
    @_processManagerInstances[processManagerName][processManagerId] = processManager


  _endProcessManager: (processManagerName, processManagerId) ->
    delete @_processManagerInstances[processManagerName][processManagerId]


  _subscribeProcessManagerToDomainEvents: (processManager, handleContextDomainEventNames, index) ->
    index.subscribeToDomainEvent (domainEvent) =>
      for handleContextDomainEventName in handleContextDomainEventNames
        if "from#{domainEvent.context}_handle#{domainEvent.name}" == handleContextDomainEventName
          @_applyDomainEventToProcessManager handleContextDomainEventName, domainEvent, processManager


  _applyDomainEventToProcessManager: (handleContextDomainEventName, domainEvent, processManager) ->
    if !processManager[handleContextDomainEventName]
      err = new Error "Tried to apply DomainEvent '#{domainEventName}' to Projection without a matching handle method"

    else
      processManager[handleContextDomainEventName] domainEvent


module.exports = new ProcessManagerService