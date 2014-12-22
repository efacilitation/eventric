###*
* @name Context
* @module Context
* @description
*
* Contexts give you boundaries for parts of your application. You can choose
* the size of such Contexts as you like. Anything from a MicroService to a complete
* application.
###
class Context

  constructor: (@name, @_eventric) ->
    @_initialized = false
    @_params = @_eventric.get()
    @_di = {}
    @_aggregateRootClasses = {}
    @_adapterClasses = {}
    @_adapterInstances = {}
    @_commandHandlers = {}
    @_queryHandlers = {}
    @_domainEventClasses = {}
    @_domainEventHandlers = {}
    @_projectionClasses = {}
    @_domainEventStreamClasses = {}
    @_domainEventStreamInstances = {}
    @_repositoryInstances = {}
    @_domainServices = {}
    @_storeClasses = {}
    @_storeInstances = {}
    @_eventBus         = new @_eventric.EventBus @_eventric
    @projectionService = new @_eventric.Projection @_eventric
    @log = @_eventric.log


  ###*
  * @name set
  * @module Context
  * @description Configure Context parameters
  *
  * @example

     exampleContext.set 'store', StoreAdapter

  *
  * @param {String} key Name of the key
  * @param {Mixed} value Value to be set
  ###
  set: (key, value) ->
    @_params[key] = value
    @


  ###*
  * @name get
  * @module Context
  * @description Get configured Context parameters
  *
  * @example

     exampleContext.set 'store', StoreAdapter

  *
  * @param {String} key Name of the Key
  ###
  get: (key) ->
    @_params[key]


  ###*
  * @name emitDomainEvent
  * @module Context
  * @description Emit Domain Event in the context
  *
  * @param {String} domainEventName Name of the DomainEvent
  * @param {Object} domainEventPayload payload for the DomainEvent
  ###
  emitDomainEvent: (domainEventName, domainEventPayload) =>
    DomainEventClass = @getDomainEvent domainEventName
    if !DomainEventClass
      throw new Error "Tried to emitDomainEvent '#{domainEventName}' which is not defined"

    domainEvent = @_createDomainEvent domainEventName, DomainEventClass, domainEventPayload
    @getDomainEventsStore().saveDomainEvent domainEvent, =>
      @publishDomainEvent domainEvent


  ###*
  * @name publishDomainEvent
  * @module Context
  * @description Publish a DomainEvent in the Context
  *
  * @param {Object} domainEvent Instance of a DomainEvent
  ###
  publishDomainEvent: (domainEvent) =>
    @_eventBus.publishDomainEvent domainEvent


  _createDomainEvent: (domainEventName, DomainEventClass, domainEventPayload) ->
    new @_eventric.DomainEvent
      id: @_eventric.generateUid()
      name: domainEventName
      context: @name
      payload: new DomainEventClass domainEventPayload


  ###*
  * @name addStore
  * @module Context
  * @description Add Store to the Context
  *
  * @param {string} storeName Name of the store
  * @param {Function} StoreClass Class of the store
  * @param {Object} Options to be passed to the store on initialize
  ###
  addStore: (storeName, StoreClass, storeOptions={}) ->
    @_storeClasses[storeName] =
      Class: StoreClass
      options: storeOptions
    @


  ###*
  * @name defineDomainEvent
  * @module Context
  * @description
  * Add a DomainEvent Class which will be used when emitting or
  * handling DomainEvents inside of the Context
  *
  * @param {String} domainEventName Name of the DomainEvent
  * @param {Function} DomainEventClass DomainEventClass
  ###
  defineDomainEvent: (domainEventName, DomainEventClass) ->
    @_domainEventClasses[domainEventName] = DomainEventClass
    @


  ###*
  * @name defineDomainEvents
  * @module Context
  * @description Define multiple DomainEvents at once
  *
  * @param {Object} domainEventClassesObj Object containing multiple DomainEventsDefinitions "name: class"
  ###
  defineDomainEvents: (domainEventClassesObj) ->
    @defineDomainEvent domainEventName, DomainEventClass for domainEventName, DomainEventClass of domainEventClassesObj
    @


  ###*
  * @name addCommandHandler
  * @module Context
  * @description
  *
  * Add CommandHandlers to the `context`. These will be available to the `command` method
  * after calling `initialize`.
  *
  * @example
    ```javascript
    exampleContext.addCommandHandler('someCommand', function(params) {
      // ...
    });
    ```
  * @param {String} commandName Name of the command
  * @param {String} commandFunction The CommandHandler Function
  ###
  addCommandHandler: (commandHandlerName, commandHandlerFn) ->
    @_commandHandlers[commandHandlerName] = =>
      command =
        id: @_eventric.generateUid()
        name: commandHandlerName
        params: arguments[0] ? null

      _di = {}
      for diFnName, diFn of @_di
        _di[diFnName] = diFn

      _di.$aggregate =
        create: (aggregateName, aggregateParams...) =>
          repository = @_getAggregateRepository aggregateName, command
          repository.create aggregateParams...

        load: (aggregateName, aggregateId) =>
          repository = @_getAggregateRepository aggregateName, command
          repository.findById aggregateId

      commandHandlerFn.apply _di, arguments
    @


  _getAggregateRepository: (aggregateName, command) =>
    repositoriesCache = {} if not repositoriesCache
    if not repositoriesCache[aggregateName]
      AggregateRoot = @_aggregateRootClasses[aggregateName]
      repository = new @_eventric.Repository
        aggregateName: aggregateName
        AggregateRoot: AggregateRoot
        context: @
        eventric: @_eventric
      repositoriesCache[aggregateName] = repository

    repositoriesCache[aggregateName].setCommand command
    repositoriesCache[aggregateName]


  ###*
  * @name addCommandHandlers
  * @module Context
  * @description Add multiple CommandHandlers at once
  *
  * @param {Object} commandObj Object containing multiple CommandHandlers "name: class"
  ###
  addCommandHandlers: (commandObj) ->
    @addCommandHandler commandHandlerName, commandFunction for commandHandlerName, commandFunction of commandObj
    @


  ###*
  * @name addQueryHandler
  * @module Context
  * @description Add QueryHandler to the `context`
  *
  * @example
    ```javascript
    exampleContext.addQueryHandler('SomeQuery', function(params) {
      // ...
    });
    ```

  * @param {String} queryHandler Name of the query
  * @param {String} queryFunction Function to execute on query
  ###
  addQueryHandler: (queryHandlerName, queryHandlerFn) ->
    @_queryHandlers[queryHandlerName] = => queryHandlerFn.apply @_di, arguments
    @


  ###*
  * @name addQueryHandlers
  * @module Context
  * @description Add multiple QueryHandlers at once
  *
  * @param {Object} queryObj Object containing multiple QueryHandlers "name: class"
  ###
  addQueryHandlers: (queryObj) ->
    @addQueryHandler queryHandlerName, queryFunction for queryHandlerName, queryFunction of queryObj
    @


  ###*
  * @name addAggregate
  * @module Context
  * @description Add Aggregates to the `context`
  *
  * @param {String} aggregateName Name of the Aggregate
  * @param {Function} AggregateRootClass AggregateRootClass
  ###
  addAggregate: (aggregateName, AggregateRootClass) ->
    @_aggregateRootClasses[aggregateName] = AggregateRootClass
    @


  ###*
  * @name addAggregates
  * @module Context
  * @description Add multiple Aggregates at once
  *
  * @param {Object} aggregatesObj Object containing multiple Aggregates "name: class"
  ###
  addAggregates: (aggregatesObj) ->
    @addAggregate aggregateName, AggregateRootClass for aggregateName, AggregateRootClass of aggregatesObj
    @


  ###*
  * @name subscribeToDomainEvent
  * @module Context
  * @description Add handler function which gets called when a specific `DomainEvent` gets triggered
  *
  * @example
    ```javascript
    exampleContext.subscribeToDomainEvent('SomethingHappened', function(domainEvent) {
      // ...
    });
    ```
  *
  * @param {String} domainEventName Name of the `DomainEvent`
  * @param {Function} Function which gets called with `domainEvent` as argument
  * @param {Object} options Options to set on the EventBus ("async: false" is default)
  ###
  subscribeToDomainEvent: (domainEventName, handlerFn, options = {}) ->
    domainEventHandler = () => handlerFn.apply @_di, arguments
    @_eventBus.subscribeToDomainEvent domainEventName, domainEventHandler, options


  ###*
  * @name subscribeToDomainEvents
  * @module Context
  * @description Add multiple DomainEventSubscribers at once
  *
  * @param {Object} domainEventHandlersObj Object containing multiple Subscribers "name: handlerFn"
  ###
  subscribeToDomainEvents: (domainEventHandlersObj) ->
    @subscribeToDomainEvent domainEventName, handlerFn for domainEventName, handlerFn of domainEventHandlersObj


  ###*
  * @name subscribeToDomainEventWithAggregateId
  * @module Context
  * @description Add handler function which gets called when a specific `DomainEvent` containing a specific AggregateId gets triggered
  *
  * @param {String} domainEventName Name of the `DomainEvent`
  * @param {String} aggregateId AggregateId
  * @param {Function} Function which gets called with `domainEvent` as argument
  * @param {Object} options Options to set on the EventBus ("async: false" is default)
  ###
  subscribeToDomainEventWithAggregateId: (domainEventName, aggregateId, handlerFn, options = {}) ->
    domainEventHandler = () => handlerFn.apply @_di, arguments
    @_eventBus.subscribeToDomainEventWithAggregateId domainEventName, aggregateId, domainEventHandler, options


  ###*
  * @name subscribeToAllDomainEvents
  * @module Context
  * @description Add handler function which gets called when any `DomainEvent` gets triggered
  *
  * @param {Function} Function which gets called with `domainEvent` as argument
  * @param {Object} options Options to set on the EventBus ("async: false" is default)
  ###
  subscribeToAllDomainEvents: (handlerFn, options = {}) ->
    domainEventHandler = () => handlerFn.apply @_di, arguments
    @_eventBus.subscribeToAllDomainEvents domainEventHandler, options


  ###*
  * @name subscribeToDomainEventStream
  * @module Context
  * @description Add DomainEventStream Definition
  *
  * @param {String} domainEventStreamName Name of the DomainEventStream
  * @param {Function} DomainEventStream Definition
  * @param {Object} Options to be used when initializing the DomainEventStream
  ###
  subscribeToDomainEventStream: (domainEventStreamName, handlerFn, options = {}) ->
    new Promise (resolve, reject) =>
      if not @_domainEventStreamClasses[domainEventStreamName]
        err = new Error "DomainEventStream Class with name #{domainEventStreamName} not added"
        @log.error err
        return reject err
      domainEventStream = new @_domainEventStreamClasses[domainEventStreamName]
      domainEventStream._domainEventsPublished = {}
      domainEventStreamId = @_eventric.generateUid()
      @_domainEventStreamInstances[domainEventStreamId] = domainEventStream

      domainEventNames = []
      for functionName, functionValue of domainEventStream
        if (functionName.indexOf 'filter') is 0 and (typeof functionValue is 'function')
          domainEventName = functionName.replace /^filter/, ''
          domainEventNames.push domainEventName

      @_applyDomainEventsFromStoreToDomainEventStream domainEventNames, domainEventStream, handlerFn
      .then =>
        for domainEventName in domainEventNames
          @subscribeToDomainEvent domainEventName, (domainEvent) ->
            if domainEventStream._domainEventsPublished[domainEvent.id]
              return

            if (domainEventStream["filter#{domainEvent.name}"] domainEvent) is true
              handlerFn domainEvent, ->

          , options

      resolve domainEventStreamId


  _applyDomainEventsFromStoreToDomainEventStream: (eventNames, domainEventStream) ->
    new Promise (resolve, reject) =>
      @findDomainEventsByName eventNames
      .then (domainEvents) =>
        if not domainEvents or domainEvents.length is 0
          return resolve eventNames

        @_eventric.eachSeries domainEvents, (domainEvent, next) =>
          if (domainEventStream["filter#{domainEvent.name}"] domainEvent) is true
            handlerFn domainEvent, ->
            domainEventStream._domainEventsPublished[domainEvent.id] = true
            next()

        , (err) ->
          return reject err if err
          resolve eventNames

      .catch (err) ->
        reject err


  ###*
  * @name addDomainService
  * @module Context
  * @description Add function which gets called when called using $domainService
  *
  * @example
    ```javascript
    exampleContext.addDomainService('DoSomethingSpecial', function(params) {
      // ...
    });
    ```
  *
  * @param {String} domainServiceName Name of the `DomainService`
  * @param {Function} Function which gets called with params as argument
  ###
  addDomainService: (domainServiceName, domainServiceFn) ->
    @_domainServices[domainServiceName] = => domainServiceFn.apply @_di, arguments
    @


  ###*
  * @name addDomainServices
  * @module Context
  * @description Add multiple DomainServices at once
  *
  * @param {Object} domainServiceObjs Object containing multiple DomainEventStreamDefinitions "name: definition"
  ###
  addDomainServices: (domainServiceObjs) ->
    @addDomainService domainServiceName, domainServiceFn for domainServiceName, domainServiceFn of domainServiceObjs
    @


  ###*
  * @name addAdapter
  * @module Context
  * @description Add adapter
  *
  * @example
    ```javascript
    exampleContext.addAdapter('SomeAdapter', function() {
      // ...
    });
    ```
  *
  * @param {String} adapterName Name of Adapter
  * @param {Function} Adapter Class
  ###
  addAdapter: (adapterName, adapterClass) ->
    @_adapterClasses[adapterName] = adapterClass
    @


  ###*
  * @name addAdapters
  * @module Context
  * @description Add multiple Adapters at once
  *
  * @param {Object} adaptersObj Object containing multiple Adapters "name: function"
  ###
  addAdapters: (adaptersObj) ->
    @addAdapter adapterName, fn for adapterName, fn of adaptersObj
    @


  ###*
  * @name addProjection
  * @module Context
  * @description Add Projection that can subscribe to and handle DomainEvents
  *
  * @param {string} projectionName Name of the Projection
  * @param {Function} The Projection Class definition
  ###
  addProjection: (projectionName, ProjectionClass) ->
    @_projectionClasses[projectionName] = ProjectionClass
    @


  ###*
  * @name addProjections
  * @module Context
  * @description Add multiple Projections at once
  *
  * @param {object} Projections key projectionName, value ProjectionClass
  ###
  addProjections: (viewsObj) ->
    @addProjection projectionName, ProjectionClass for projectionName, ProjectionClass of viewsObj
    @


  ###*
  * @name addDomainEventStream
  * @module Context
  * @description Add DomainEventStream which projections can subscribe to
  *
  * @param {string} domainEventStreamName Name of the Stream
  * @param {Function} The DomainEventStream Class definition
  ###
  addDomainEventStream: (domainEventStreamName, DomainEventStreamClass) ->
    @_domainEventStreamClasses[domainEventStreamName] = DomainEventStreamClass
    @


  ###*
  * @name addDomainEventStreams
  * @module Context
  * @description Add multiple DomainEventStreams at once
  *
  * @param {object} DomainEventStreams key domainEventStreamName, value DomainEventStreamClass
  ###
  addDomainEventStreams: (viewsObj) ->
    @addDomainEventStream domainEventStreamName, DomainEventStreamClass for domainEventStreamName, DomainEventStreamClass of viewsObj
    @


  ###*
  * @name getProjectionInstance
  * @module Context
  * @description Get ProjectionInstance
  *
  * @param {String} projectionId ProjectionId
  ###
  getProjectionInstance: (projectionId) ->
    @projectionService.getInstance projectionId


  ###*
  * @name destroyProjectionInstance
  * @module Context
  * @description Destroy a ProjectionInstance
  *
  * @param {String} projectionId ProjectionId
  ###
  destroyProjectionInstance: (projectionId) ->
    @projectionService.destroyInstance projectionId, @


  ###*
  * @name initializeProjectionInstance
  * @module Context
  * @description Initialize a ProjectionInstance
  *
  * @param {String} projectionName Name of the Projection
  * @param {Object} params Object containing Projection Parameters
  ###
  initializeProjectionInstance: (projectionName, params) ->
    if not @_projectionClasses[projectionName]
      err = "Given projection #{projectionName} not registered on context"
      @_eventric.log.error err
      err = new Error err
      return err

    @projectionService.initializeInstance projectionName, @_projectionClasses[projectionName], params, @


  ###*
  * @name initialize
  * @module Context
  * @description Initialize the Context
  *
  * @example
    ```javascript
    exampleContext.initialize(function() {
      // ...
    })
    ```
  ###
  initialize: ->
    new Promise (resolve, reject) =>
      @log.debug "[#{@name}] Initializing"
      @log.debug "[#{@name}] Initializing Store"
      @_initializeStores()
      .then =>
        @log.debug "[#{@name}] Finished initializing Store"
        @_di =
          $adapter: => @getAdapter.apply @, arguments
          $query: => @query.apply @, arguments
          $domainService: =>
            (@getDomainService arguments[0]).apply @, [arguments[1], arguments[2]]
          $projectionStore: => @getProjectionStore.apply @, arguments
          $emitDomainEvent: => @emitDomainEvent.apply @, arguments

        @log.debug "[#{@name}] Initializing Adapters"
        @_initializeAdapters()
      .then =>
        @log.debug "[#{@name}] Finished initializing Adapters"
        @log.debug "[#{@name}] Initializing Projections"
        @_initializeProjections()
      .then =>
        @log.debug "[#{@name}] Finished initializing Projections"
        @log.debug "[#{@name}] Finished initializing"
        @_initialized = true
        resolve()
      .catch (err) ->
        reject err


  _initializeStores: ->
    new Promise (resolve, reject) =>
      stores = []
      for storeName, store of (@_eventric.defaults @_storeClasses, @_eventric.getStores())
        stores.push
          name: storeName
          Class: store.Class
          options: store.options

      @_eventric.eachSeries stores, (store, next) =>
        @log.debug "[#{@name}] Initializing Store #{store.name}"
        @_storeInstances[store.name] = new store.Class
        @_storeInstances[store.name].initialize @, store.options
        .then =>
          @log.debug "[#{@name}] Finished initializing Store #{store.name}"
          next()

      , (err) ->
        return reject err if err
        resolve()


  _initializeProjections: ->
    new Promise (resolve, reject) =>
      projections = []
      for projectionName, ProjectionClass of @_projectionClasses
        projections.push
          name: projectionName
          class: ProjectionClass

      @_eventric.eachSeries projections, (projection, next) =>
        eventNames = null
        @log.debug "[#{@name}] Initializing Projection #{projection.name}"
        @projectionService.initializeInstance projection.name, projection.class, {}, @
        .then (projectionId) =>
          @log.debug "[#{@name}] Finished initializing Projection #{projection.name}"
          next()

        .catch (err) ->
          reject err

      , (err) =>
        return reject err if err
        resolve()


  _initializeAdapters: ->
    new Promise (resolve, reject) =>
      for adapterName, adapterClass of @_adapterClasses
        adapter = new @_adapterClasses[adapterName]
        adapter.initialize?()

        @_adapterInstances[adapterName] = adapter

      resolve()


  ###*
  * @name getProjection
  * @module Context
  * @description Get a Projection Instance after initialize()
  *
  * @param {String} projectionName Name of the Projection
  ###
  getProjection: (projectionId) ->
    @projectionService.getInstance projectionId


  ###*
  * @name getAdapter
  * @module Context
  * @description Get a Adapter Instance after initialize()
  *
  * @param {String} adapterName Name of the Adapter
  ###
  getAdapter: (adapterName) ->
    @_adapterInstances[adapterName]


  ###*
  * @name getDomainEvent
  * @module Context
  * @description Get a DomainEvent Class after initialize()
  *
  * @param {String} domainEventName Name of the DomainEvent
  ###
  getDomainEvent: (domainEventName) ->
    @_domainEventClasses[domainEventName]


  ###*
  * @name getDomainService
  * @module Context
  * @description Get a DomainService after initialize()
  *
  * @param {String} domainServiceName Name of the DomainService
  ###
  getDomainService: (domainServiceName) ->
    @_domainServices[domainServiceName]


  ###*
  * @name getDomainEventsStore
  * @module Context
  * @description Get the current default DomainEventsStore
  ###
  getDomainEventsStore: ->
    storeName = @get 'default domain events store'
    @_storeInstances[storeName]


  ###*
  * @name saveDomainEvent
  * @module Context
  * @description Save a DomainEvent to the default DomainEventStore
  *
  * @param {Object} domainEvent Instance of a DomainEvent
  ###
  saveDomainEvent: (domainEvent) ->
    new Promise (resolve, reject) =>
      @getDomainEventsStore().saveDomainEvent domainEvent, (err, events) =>
        @publishDomainEvent domainEvent
        return reject err if err
        resolve events


  ###*
  * @name findAllDomainEvents
  * @module Context
  * @description Return all DomainEvents from the default DomainEventStore
  ###
  findAllDomainEvents: ->
    new Promise (resolve, reject) =>
      @getDomainEventsStore().findAllDomainEvents (err, events) ->
        return reject err if err
        resolve events


  ###*
  * @name findDomainEventsByName
  * @module Context
  * @description Return DomainEvents from the default DomainEventStore which match the given DomainEventName
  *
  * @param {String} domainEventName Name of the DomainEvent to be returned
  ###
  findDomainEventsByName: (findArguments...) ->
    new Promise (resolve, reject) =>
      @getDomainEventsStore().findDomainEventsByName findArguments..., (err, events) ->
        return reject err if err
        resolve events


  ###*
  * @name findDomainEventsByAggregateId
  * @module Context
  * @description Return DomainEvents from the default DomainEventStore which match the given AggregateId
  *
  * @param {String} aggregateId AggregateId of the DomainEvents to be found
  ###
  findDomainEventsByAggregateId: (findArguments...) ->
    new Promise (resolve, reject) =>
      @getDomainEventsStore().findDomainEventsByAggregateId findArguments..., (err, events) ->
        return reject err if err
        resolve events


  ###*
  * @name findDomainEventsByNameAndAggregateId
  * @module Context
  * @description Return DomainEvents from the default DomainEventStore which match the given DomainEventName and AggregateId
  *
  * @param {String} domainEventName Name of the DomainEvents to be found
  * @param {String} aggregateId AggregateId of the DomainEvents to be found
  ###
  findDomainEventsByNameAndAggregateId: (findArguments...) ->
    new Promise (resolve, reject) =>
      @getDomainEventsStore().findDomainEventsByNameAndAggregateId findArguments..., (err, events) ->
        return reject err if err
        resolve events


  ###*
  * @name findDomainEventsByAggregateName
  * @module Context
  * @description Return DomainEvents from the default DomainEventStore which match the given AggregateName
  *
  * @param {String} aggregateName AggregateName of the DomainEvents to be found
  ###
  findDomainEventsByAggregateName: (findArguments...) ->
    new Promise (resolve, reject) =>
      @getDomainEventsStore().findDomainEventsByAggregateName findArguments..., (err, events) ->
        return reject err if err
        resolve events


  ###*
  * @name getProjectionStore
  * @module Context
  * @description Get a specific ProjectionStore Instance
  *
  * @param {String} storeName Name of the Store
  * @param {String} projectionName Name of the Projection
  ###
  getProjectionStore: (storeName, projectionName) =>  new Promise (resolve, reject) =>
    if not @_storeInstances[storeName]
      err = "Requested Store with name #{storeName} not found"
      @log.error err
      return reject err

    @_storeInstances[storeName].getProjectionStore projectionName
    .then (projectionStore) ->
      resolve projectionStore


  ###*
  * @name clearProjectionStore
  * @module Context
  * @description Clear the ProjectionStore
  *
  * @param {String} storeName Name of the Store
  * @param {String} projectionName Name of the Projection
  ###
  clearProjectionStore: (storeName, projectionName) =>  new Promise (resolve, reject) =>
    if not @_storeInstances[storeName]
      err = "Requested Store with name #{storeName} not found"
      @log.error err
      return reject err

    @_storeInstances[storeName].clearProjectionStore projectionName
    .then ->
      resolve()


  ###*
  * @name getEventBus
  * @module Context
  * @description Get the EventBus
  ###
  getEventBus: ->
    @_eventBus


  ###*
  * @name command
  * @module Context
  * @description Execute previously added CommandHandlers
  *
  * @example
    ```javascript
    exampleContext.command('doSomething');
    ```
  *
  * @param {String} `commandName` Name of the CommandHandler to be executed
  * @param {Object} `commandParams` Parameters for the CommandHandler function
  ###
  command: (commandName, commandParams) ->
    @log.debug 'Got Command', commandName

    new Promise (resolve, reject) =>
      if not @_initialized
        err = 'Context not initialized yet'
        @log.error err
        err = new Error err
        return reject err

      if @_commandHandlers[commandName]
        @_commandHandlers[commandName] commandParams, (err, result) =>
          @log.debug 'Completed Command', commandName
          @_eventric.nextTick =>
            if err
              reject err
            else
              resolve result

      else
        err = "Given command #{commandName} not registered on context"
        @log.error err
        err = new Error err
        reject err


  ###*
  * @name query
  * @module Context
  * @description Execute previously added QueryHandler
  *
  * @example
    ```javascript
    exampleContext.query('getSomething');
    ```
  *
  * @param {String} `queryName` Name of the QueryHandler to be executed
  * @param {Object} `queryParams` Parameters for the QueryHandler function
  ###
  query: (queryName, queryParams) ->
    @log.debug 'Got Query', queryName

    new Promise (resolve, reject) =>
      if not @_initialized
        err = 'Context not initialized yet'
        @log.error err
        err = new Error err
        reject err
        return

      if @_queryHandlers[queryName]
        @_queryHandlers[queryName] queryParams, (err, result) =>
          @log.debug 'Completed Query', queryName
          @_eventric.nextTick =>
            if err
              reject err
            else
              resolve result

      else
        err = "Given query #{queryName} not registered on context"
        @log.error err
        err = new Error err
        reject err


  ###*
  * @name enableWaitingMode
  * @module Context
  * @description Enables the WaitingMode
  ###
  enableWaitingMode: ->
    @set 'waiting mode', true


  ###*
  * @name disableWaitingMode
  * @module Context
  * @description Disables the WaitingMode
  ###
  disableWaitingMode: ->
    @set 'waiting mode', false


  ###*
  * @name isWaitingModeEnabled
  * @module Context
  * @description Returns if the WaitingMode is enabled
  ###
  isWaitingModeEnabled: ->
    @get 'waiting mode'


module.exports = Context
