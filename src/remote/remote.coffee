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


  ###*
  * @name set
  *
  * @module Remote
  ###
  set: (key, value) ->
    @_params[key] = value
    @


  ###*
  * @name get
  *
  * @module Remote
  ###
  get: (key) ->
    @_params[key]


  ###*
  * @name command
  *
  * @module Remote
  ###
  command: ->
    @_rpc 'command', arguments


  ###*
  * @name query
  *
  * @module Remote
  ###
  query: ->
    @_rpc 'query', arguments


  ###*
  * @name findAllDomainEvents
  *
  * @module Remote
  ###
  findAllDomainEvents: ->
    @_rpc 'findAllDomainEvents', arguments


  ###*
  * @name findDomainEventsByName
  *
  * @module Remote
  ###
  findDomainEventsByName: ->
    @_rpc 'findDomainEventsByName', arguments


  ###*
  * @name findDomainEventsByAggregateId
  *
  * @module Remote
  ###
  findDomainEventsByAggregateId: ->
    @_rpc 'findDomainEventsByAggregateId', arguments


  ###*
  * @name findDomainEventsByAggregateName
  *
  * @module Remote
  ###
  findDomainEventsByAggregateName: ->
    @_rpc 'findDomainEventsByAggregateName', arguments


  ###*
  * @name findDomainEventsByNameAndAggregateId
  *
  * @module Remote
  ###
  findDomainEventsByNameAndAggregateId: ->
    @_rpc 'findDomainEventsByNameAndAggregateId', arguments


  ###*
  * @name subscribeToAllDomainEvents
  *
  * @module Remote
  ###
  subscribeToAllDomainEvents: (handlerFn, options = {}) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.subscribe @_contextName, handlerFn


  ###*
  * @name subscribeToDomainEvent
  *
  * @module Remote
  ###
  subscribeToDomainEvent: (domainEventName, handlerFn, options = {}) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.subscribe @_contextName, domainEventName, handlerFn


  ###*
  * @name subscribeToDomainEventsWithAggregateId
  *
  * @module Remote
  ###
  subscribeToDomainEventWithAggregateId: (domainEventName, aggregateId, handlerFn, options = {}) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.subscribe @_contextName, domainEventName, aggregateId, handlerFn


  ###*
  * @name unsubscribeFromDomainEvent
  *
  * @module Remote
  ###
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


  ###*
  * @name addClient
  *
  * @module Remote
  ###
  addClient: (clientName, client) ->
    @_clients[clientName] = client
    @


  ###*
  * @name getClient
  *
  * @module Remote
  ###
  getClient: (clientName) ->
    @_clients[clientName]


  ###*
  * @name addProjection
  *
  * @module Remote
  ###
  addProjection: (projectionName, projectionClass) ->
    @_projectionClasses[projectionName] = projectionClass
    @


  ###*
  * @name initializeProjection
  *
  * @module Remote
  ###
  initializeProjection: (projectionObject, params) ->
    projectionService.initializeInstance '', projectionObject, params, @


  ###*
  * @name initializeProjectionInstance
  *
  * @module Remote
  ###
  initializeProjectionInstance: (projectionName, params) ->
    if not @_projectionClasses[projectionName]
      err = "Given projection #{projectionName} not registered on remote"
      eventric.log.error err
      err = new Error err
      return err

    projectionService.initializeInstance projectionName, @_projectionClasses[projectionName], params, @


  ###*
  * @name getProjectionInstance
  *
  * @module Remote
  ###
  getProjectionInstance: (projectionId) ->
    projectionService.getInstance projectionId


  ###*
  * @name destroyProjectionInstance
  *
  * @module Remote
  ###
  destroyProjectionInstance: (projectionId) ->
    projectionService.destroyInstance projectionId, @


module.exports = Remote
