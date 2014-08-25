eventric      = require 'eventric'
log           = eventric.log
EventEmitter2 = require('./helper/EventEmitter2').EventEmitter2
_             = require './helper/underscore'


class Remote

  constructor: (@_contextName) ->
    @_params = {}
    @_clients = {}
    @_projectionClasses = {}
    @_projectionInstances = {}
    @_handlerFunctions = {}
    @addClient 'inmemory', (require './remote_inmemory').client
    @set 'default client', 'inmemory'


  set: (key, value) ->
    @_params[key] = value
    @


  get: (key) ->
    @_params[key]


  command: ->
    @_rpc 'command', arguments


  query: ->
    @_rpc 'query', arguments


  findAllDomainEvents: ->
    @_rpc 'findAllDomainEvents', arguments


  findDomainEventsByName: ->
    @_rpc 'findDomainEventsByName', arguments


  findDomainEventsByAggregateId: ->
    @_rpc 'findDomainEventsByAggregateId', arguments


  findDomainEventsByAggregateName: ->
    @_rpc 'findDomainEventsByAggregateName', arguments


  findDomainEventsByNameAndAggregateId: ->
    @_rpc 'findDomainEventsByNameAndAggregateId', arguments


  subscribeToDomainEvent: ([domainEventName]..., handlerFn) ->
    clientName = @get 'default client'
    client = @getClient clientName
    if domainEventName
      client.subscribe @_contextName, domainEventName, handlerFn
    else
      client.subscribe @_contextName, handlerFn


  subscribeToDomainEventWithAggregateId: (domainEventName, aggregateId, handlerFn) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.subscribe @_contextName, domainEventName, aggregateId, handlerFn


  unsubscribeFromDomainEvent: (subscriberId) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.unsubscribe subscriberId


  _rpc: (method, params) ->
    new Promise (resolve, reject) =>
      clientName = @get 'default client'
      client = @getClient clientName
      client.rpc
        contextName: @_contextName
        method: method
        params: Array.prototype.slice.call params
      , (err, result) ->
        if err
          reject err
        else
          resolve result


  addClient: (clientName, client) ->
    @_clients[clientName] = client
    @


  getClient: (clientName) ->
    @_clients[clientName]


  addProjection: (projectionName, projectionClass) ->
    @_projectionClasses[projectionName] = projectionClass
    @


  initializeProjectionInstance: (projectionName, params) ->
    new Promise (resolve, reject) =>
      if not @_projectionClasses[projectionName]
        err = "Given projection #{projectionName} not registered on remote"
        log.error err
        err = new Error err
        return reject err

      Projection = @_projectionClasses[projectionName]

      projection = new Projection
      projection.eventBus = new EventEmitter2()

      aggregateId = null
      projection.$subscribeHandlersWithAggregateId = (_aggregateId) ->
        aggregateId = _aggregateId
      projection.initialize? params

      projectionId = eventric.generateUid()

      eventNames = []
      eventHandlers = {}
      for handlerFnName in Object.keys(Projection::)
        continue unless handlerFnName.indexOf("handle") == 0
        eventName = handlerFnName.replace /^handle/, ''
        eventNames.push eventName

        handlerFn = ->
          projection[handlerFnName].apply projection, arguments
          projection.eventBus.emit 'changed', projection


        eventHandlers[eventName] = handlerFn

        if aggregateId
          subscriberId = @subscribeToDomainEventWithAggregateId eventName, aggregateId, handlerFn
        else
          subscriberId = @subscribeToDomainEvent eventName, handlerFn

        @_handlerFunctions[projectionId] ?= []
        @_handlerFunctions[projectionId].push subscriberId

      if aggregateId
        findEvents = @findDomainEventsByNameAndAggregateId eventNames, aggregateId
      else
        findEvents = @findDomainEventsByName eventNames

      findEvents.then (domainEvents) =>
        # TODO: performance optimizing, nextTick?
        for domainEvent in domainEvents
          eventHandlers[domainEvent.name] domainEvent

        @_projectionInstances[projectionId] = projection
        resolve projectionId


  getProjectionInstance: (projectionId) ->
    @_projectionInstances[projectionId]


  destroyProjectionInstance: (projectionId) ->
    for subscriberId in @_handlerFunctions[projectionId]
      @unsubscribeFromDomainEvent subscriberId
    delete @_handlerFunctions[projectionId]
    delete @_projectionInstances[projectionId]


module.exports = Remote
