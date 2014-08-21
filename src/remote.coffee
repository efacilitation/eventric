eventric = require 'eventric'
log      = eventric.log

class Remote

  constructor: (@_contextName) ->
    @_params = {}
    @_clients = {}
    @_projectionClasses = {}
    @_projectionInstances = {}
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


  subscribeToDomainEvent: (eventName, handlerFn) ->
    clientName = @get 'default client'
    client = @getClient clientName
    fullEventName = "#{@_contextName}/#{eventName}"
    client.subscribe fullEventName, handlerFn


  subscribeToDomainEventWithAggregateId: (eventName, aggregateId, handlerFn) ->
    @subscribeToDomainEvent "#{eventName}/#{aggregateId}", handlerFn


  unsubscribeFromDomainEvent: (eventName, handlerFn) ->
    clientName = @get 'default client'
    client = @getClient clientName
    fullEventName = "#{@_contextName}/#{eventName}"
    client.unsubscribe fullEventName, handlerFn


  unsubscribeFromDomainEventWithAggregateId: (eventName, aggregateId, handlerFn) ->
    @unsubscribeFromDomainEvent "#{eventName}/#{aggregateId}", handlerFn


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
      if @_projectionClasses[projectionName]
        Projection = @_projectionClasses[projectionName]
        projection = new Projection

        for handlerFnName in Object.keys(Projection::)
          continue unless handlerFnName.indexOf("handle") == 0
          eventName = handlerFnName.replace /^handle/, ''
          @subscribeToDomainEvent eventName, ->
            projection[handlerFnName].apply projection, arguments

        projectionId = eventric.generateUid()
        @_projectionInstances[projectionId] = projection
        resolve projectionId
      else
        err = "Given projection #{projectionName} not registered on remote"
        log.error err
        err = new Error err
        reject err


  getProjectionInstance: (projectionId) ->
    @_projectionInstances[projectionId]


module.exports = Remote
