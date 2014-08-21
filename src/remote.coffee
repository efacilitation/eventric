eventric = require 'eventric'
log      = eventric.log

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


  unsubscribeFromDomainEvent: ([domainEventName]..., handlerFn) ->
    clientName = @get 'default client'
    client = @getClient clientName
    if domainEventName
      client.unsubscribe @_contextName, domainEventName, handlerFn
    else
      client.unsubscribe @_contextName, handlerFn


  unsubscribeFromDomainEventWithAggregateId: (domainEventName, aggregateId, handlerFn) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.unsubscribe @_contextName, domainEventName, aggregateId, handlerFn


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

      aggregateId = null
      di =
        $subscribeHandlersWithAggregateId: (_aggregateId) ->
          aggregateId = _aggregateId
      projection.initialize?.apply di, [params]

      projectionId = eventric.generateUid()

      for handlerFnName in Object.keys(Projection::)
        continue unless handlerFnName.indexOf("handle") == 0
        eventName = handlerFnName.replace /^handle/, ''
        handlerFn = ->
          projection[handlerFnName].apply projection, arguments
        if aggregateId
          @subscribeToDomainEventWithAggregateId eventName, aggregateId, handlerFn
        else
          @subscribeToDomainEvent eventName, handlerFn

        @_handlerFunctions[projectionId] ?= []
        @_handlerFunctions[projectionId].push
          eventName: eventName
          aggregateId: aggregateId
          handlerFn: handlerFn

      @_projectionInstances[projectionId] = projection
      resolve projectionId


  getProjectionInstance: (projectionId) ->
    @_projectionInstances[projectionId]


  destroyProjectionInstance: (projectionId) ->
    for projectionHandlers in @_handlerFunctions[projectionId]
      if projectionHandlers.aggregateId
        @unsubscribeFromDomainEventWithAggregateId projectionHandlers.eventName, projectionHandlers.aggregateId, projectionHandlers.handlerFn
      else
        @unsubscribeFromDomainEvent projectionHandlers.eventName, projectionHandlers.handlerFn

    delete @_handlerFunctions[projectionId]
    delete @_projectionInstances[projectionId]


module.exports = Remote
