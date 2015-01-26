###*
* @name Remote
* @module Remote
* @description
*
* Remotes let you remotely use Contexts
###
class Remote

  constructor: (@_contextName, @_eventric) ->
    @name = @_contextName

    @InMemoryRemote = require './inmemory'

    @_params = {}
    @_clients = {}
    @_projectionClasses = {}
    @_projectionInstances = {}
    @_handlerFunctions = {}
    @projectionService = new @_eventric.Projection @_eventric
    @addClient 'inmemory', @InMemoryRemote.client
    @set 'default client', 'inmemory'


  ###*
  * @name set
  * @module Remote
  * @description Configure Remote parameters
  *
  * @example

     exampleRemote.set 'store', StoreAdapter

  *
  * @param {String} key Name of the key
  * @param {Mixed} value Value to be set
  ###
  set: (key, value) ->
    @_params[key] = value
    @


  ###*
  * @name get
  * @module Remote
  * @description Get configured Remote parameters
  *
  * @example

     exampleRemote.set 'store', StoreAdapter

  *
  * @param {String} key Name of the Key
  ###
  get: (key) ->
    @_params[key]


  ###*
  * @name command
  * @module Remote
  * @description Execute previously added CommandHandlers
  *
  * @example
    ```javascript
    exampleRemote.command('doSomething');
    ```
  *
  * @param {String} `commandName` Name of the CommandHandler to be executed
  * @param {Object} `commandParams` Parameters for the CommandHandler function
  ###
  command: ->
    @_rpc 'command', arguments


  ###*
  * @name query
  * @module Remote
  * @description Execute previously added QueryHandler
  *
  * @example
    ```javascript
    exampleRemote.query('getSomething');
    ```
  *
  * @param {String} `queryName` Name of the QueryHandler to be executed
  * @param {Object} `queryParams` Parameters for the QueryHandler function
  ###
  query: ->
    @_rpc 'query', arguments


  ###*
  * @name findAllDomainEvents
  * @module Remote
  * @description Return all DomainEvents from the default DomainEventStore
  ###

  findAllDomainEvents: ->
    @_rpc 'findAllDomainEvents', arguments


  ###*
  * @name findDomainEventsByName
  * @module Remote
  * @description Return DomainEvents from the default DomainEventStore which match the given DomainEventName
  *
  * @param {String} domainEventName Name of the DomainEvent to be returned
  ###
  findDomainEventsByName: ->
    @_rpc 'findDomainEventsByName', arguments


  ###*
  * @name findDomainEventsByAggregateId
  * @module Remote
  * @description Return DomainEvents from the default DomainEventStore which match the given AggregateId
  *
  * @param {String} aggregateId AggregateId of the DomainEvents to be found
  ###
  findDomainEventsByAggregateId: ->
    @_rpc 'findDomainEventsByAggregateId', arguments


  ###*
  * @name findDomainEventsByAggregateName
  * @module Remote
  * @description Return DomainEvents from the default DomainEventStore which match the given AggregateName
  *
  * @param {String} aggregateName AggregateName of the DomainEvents to be found
  ###
  findDomainEventsByAggregateName: ->
    @_rpc 'findDomainEventsByAggregateName', arguments


  ###*
  * @name findDomainEventsByNameAndAggregateId
  * @module Remote
  * @description Return DomainEvents from the default DomainEventStore which match the given DomainEventName and AggregateId
  *
  * @param {String} domainEventName Name of the DomainEvents to be found
  * @param {String} aggregateId AggregateId of the DomainEvents to be found
  ###
  findDomainEventsByNameAndAggregateId: ->
    @_rpc 'findDomainEventsByNameAndAggregateId', arguments


  ###*
  * @name subscribeToAllDomainEvents
  * @module Remote
  * @description Add handler function which gets called when any `DomainEvent` gets triggered
  *
  * @param {Function} Function which gets called with `domainEvent` as argument
  * @param {Object} options Options to set on the EventBus ("async: false" is default)
  ###
  subscribeToAllDomainEvents: (handlerFn, options = {}) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.subscribe @_contextName, handlerFn


  ###*
  * @name subscribeToDomainEvent
  * @module Remote
  * @description Add handler function which gets called when a specific `DomainEvent` gets triggered
  *
  * @example
    ```javascript
    exampleRemote.subscribeToDomainEvent('SomethingHappened', function(domainEvent) {
      // ...
    });
    ```
  *
  * @param {String} domainEventName Name of the `DomainEvent`
  * @param {Function} Function which gets called with `domainEvent` as argument
  * @param {Object} options Options to set on the EventBus ("async: false" is default)
  ###
  subscribeToDomainEvent: (domainEventName, handlerFn, options = {}) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.subscribe @_contextName, domainEventName, handlerFn


  ###*
  * @name subscribeToDomainEventWithAggregateId
  * @module Remote
  * @description Add handler function which gets called when a specific `DomainEvent` containing a specific AggregateId gets triggered
  *
  * @param {String} domainEventName Name of the `DomainEvent`
  * @param {String} aggregateId AggregateId
  * @param {Function} Function which gets called with `domainEvent` as argument
  * @param {Object} options Options to set on the EventBus ("async: false" is default)
  ###
  subscribeToDomainEventWithAggregateId: (domainEventName, aggregateId, handlerFn, options = {}) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.subscribe @_contextName, domainEventName, aggregateId, handlerFn


  ###*
  * @name subscribeToDomainEventWithAggregateId
  * @module Remote
  * @description Add handler function which gets called when a specific `DomainEvent` containing a specific AggregateId gets triggered
  *
  * @param {String} domainEventStreamName Name of the `DomainEvent`
  * @param {Function} Function which gets called with `domainEvent` as argument
  * @param {Object} options Options to set on the EventBus ("async: false" is default)
  ###
  subscribeToDomainEventStream: ->
    @_rpc 'subscribeToDomainEventStream', arguments


  ###*
  * @name unsubscribeFromDomainEvent
  * @module Remote
  * @description Unsubscribe from a DomainEvent
  *
  * @param {String} subscriber SubscriberId
  ###
  unsubscribeFromDomainEvent: (subscriberId) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.unsubscribe subscriberId


  _rpc: (method, params) ->
    clientName = @get 'default client'
    client = @getClient clientName
    client.rpc
      contextName: @_contextName
      method: method
      params: Array.prototype.slice.call params


  ###*
  * @name addClient
  * @module Remote
  * @description Add a RemoteClient
  *
  * @param {String} clientName Name of the Client
  * @param {Object} client Object containing an initialized Client
  ###
  addClient: (clientName, client) ->
    @_clients[clientName] = client
    @


  ###*
  * @name getClient
  * @module Remote
  * @description Get a RemoteClient
  *
  * @param {String} clientName Name of the Client
  ###
  getClient: (clientName) ->
    @_clients[clientName]


  ###*
  * @name addProjection
  * @module Remote
  * @description Add Projection that can subscribe to and handle DomainEvents
  *
  * @param {string} projectionName Name of the Projection
  * @param {Function} The Projection Class definition
  ###
  addProjection: (projectionName, projectionClass) ->
    @_projectionClasses[projectionName] = projectionClass
    @


  ###*
  * @name initializeProjection
  * @module Remote
  * @description Initialize a Projection based on an Object
  *
  * @param {Object} projectionObject Projection Object
  * @param {Object} params Object containing Projection Parameters
  ###
  initializeProjection: (projectionObject, params) ->
    @projectionService.initializeInstance '', projectionObject, params, @


  ###*
  * @name initializeProjectionInstance
  * @module Remote
  * @description Initialize a ProjectionInstance
  *
  * @param {String} projectionId ProjectionId
  * @param {Object} params Object containing Projection Parameters
  ###
  initializeProjectionInstance: (projectionName, params) ->
    if not @_projectionClasses[projectionName]
      err = "Given projection #{projectionName} not registered on remote"
      @_eventric.log.error err
      err = new Error err
      return err

    @projectionService.initializeInstance projectionName, @_projectionClasses[projectionName], params, @


  ###*
  * @name getProjectionInstance
  * @module Remote
  * @description Get a Projection Instance
  *
  * @param {String} projectionId ProjectionId
  ###
  getProjectionInstance: (projectionId) ->
    @projectionService.getInstance projectionId


  ###*
  * @name destroyProjectionInstance
  * @module Remote
  * @description Destroy a ProjectionInstance
  *
  * @param {String} projectionId ProjectionId
  ###

  destroyProjectionInstance: (projectionId) ->
    @projectionService.destroyInstance projectionId, @


module.exports = Remote
