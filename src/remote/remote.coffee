eventric          = require 'eventric'
PubSub            = require 'eventric/src/pub_sub'
projectionService = require 'eventric/src/projection'


class Remote extends PubSub

  constructor: (@_contextName) ->
    super
    @name = @_contextName
    @_params = {}
    @_clients = {}
    @_projectionClasses = {}
    @_projectionInstances = {}
    @_handlerFunctions = {}
    @addClient 'inmemory', (require 'eventric/src/remote/inmemory').client
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


  subscribeToAllDomainEvents: (handlerFn, options = {}) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.subscribe @_contextName, handlerFn


  subscribeToDomainEvent: (domainEventName, handlerFn, options = {}) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.subscribe @_contextName, domainEventName, handlerFn


  subscribeToDomainEventWithAggregateId: (domainEventName, aggregateId, handlerFn, options = {}) ->
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
      eventric.log.error err
      err = new Error err
      return err

    projectionService.initializeInstance
      name: projectionName
      class: @_projectionClasses[projectionName]
    , params, @


  getProjectionInstance: (projectionId) ->
    projectionService.getInstance projectionId


  destroyProjectionInstance: (projectionId) ->
    projectionService.destroyInstance projectionId, @


module.exports = Remote
