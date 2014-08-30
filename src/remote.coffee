eventric      = require 'eventric'
log           = eventric.log
PubSub        = require './pub_sub'
projection    = require './projection'


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
    if not @_projectionClasses[projectionName]
      err = "Given projection #{projectionName} not registered on remote"
      log.error err
      err = new Error err
      return reject err

    projection.initializeInstance @_projectionClasses[projectionName], params, @


  getProjectionInstance: (projectionId) ->
    projection.getInstance projectionId


  destroyProjectionInstance: (projectionId) ->
    projection.destroyInstance projectionId, @


module.exports = Remote
