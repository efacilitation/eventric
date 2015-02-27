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
    @_commandHandlers = {}
    @_queryHandlers = {}
    @_domainEventClasses = {}
    @_domainEventHandlers = {}
    @_projectionClasses = {}
    @_domainEventStreamClasses = {}
    @_domainEventStreamInstances = {}
    @_repositoryInstances = {}
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
    @saveAndPublishDomainEvent domainEvent
    .then =>
      @_eventric.log.debug "Created and Handled DomainEvent in Context", domainEvent


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
    @_commandHandlers[commandHandlerName] = commandHandlerFn
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
    @_queryHandlers[queryHandlerName] = queryHandlerFn
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
  ###
  subscribeToDomainEvent: (domainEventName, handlerFn) ->
    domainEventHandler = () => handlerFn.apply @_di, arguments
    @_eventBus.subscribeToDomainEvent domainEventName, domainEventHandler


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
  ###
  subscribeToDomainEventWithAggregateId: (domainEventName, aggregateId, handlerFn) ->
    domainEventHandler = () => handlerFn.apply @_di, arguments
    @_eventBus.subscribeToDomainEventWithAggregateId domainEventName, aggregateId, domainEventHandler


  ###*
  * @name subscribeToAllDomainEvents
  * @module Context
  * @description Add handler function which gets called when any `DomainEvent` gets triggered
  *
  * @param {Function} Function which gets called with `domainEvent` as argument
  ###
  subscribeToAllDomainEvents: (handlerFn) ->
    domainEventHandler = () => handlerFn.apply @_di, arguments
    @_eventBus.subscribeToAllDomainEvents domainEventHandler


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
          $query: => @query.apply @, arguments
          $projectionStore: => @getProjectionStore.apply @, arguments
          $emitDomainEvent: => @emitDomainEvent.apply @, arguments

      .then =>
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

        .catch (err) ->
          next err

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
  * @name getDomainEvent
  * @module Context
  * @description Get a DomainEvent Class after initialize()
  *
  * @param {String} domainEventName Name of the DomainEvent
  ###
  getDomainEvent: (domainEventName) ->
    @_domainEventClasses[domainEventName]


  ###*
  * @name getDomainEventsStore
  * @module Context
  * @description Get the current default DomainEventsStore
  ###
  getDomainEventsStore: ->
    storeName = @get 'default domain events store'
    @_storeInstances[storeName]


  ###*
  * @name saveAndPublishDomainEvent
  * @module Context
  * @description Save a DomainEvent to the default DomainEventStore
  *
  * @param {Object} domainEvent Instance of a DomainEvent
  ###
  saveAndPublishDomainEvent: (domainEvent) ->  new Promise (resolve, reject) =>
    @getDomainEventsStore().saveDomainEvent domainEvent
    .then =>
      @publishDomainEvent domainEvent
    .then (err) ->
      return reject err if err
      resolve domainEvent


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

    .catch (err) ->
      reject err


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

    .catch (err) ->
      reject err


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
  command: (commandName, commandParams) ->  new Promise (resolve, reject) =>
    command =
      id: @_eventric.generateUid()
      name: commandName
      params: commandParams
    @log.debug 'Got Command', command

    if not @_initialized
      err = 'Context not initialized yet'
      @log.error err
      err = new Error err
      return reject err

    if not @_commandHandlers[commandName]
      err = "Given command #{commandName} not registered on context"
      @log.error err
      err = new Error err
      return reject err


    # TODO: extract to "injected services"
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


    commandPromise = null
    commandHandlerFn = @_commandHandlers[commandName]
    if commandHandlerFn.length <= 1
      commandPromise = commandHandlerFn.apply _di, [commandParams]
      if commandPromise not instanceof Promise
        err = "CommandHandler #{commandName} didnt return a promise and no promise argument defined."
        @log.error err
        return reject err
    else
      commandPromise = new Promise (resolve, reject) =>
        commandHandlerFn.apply _di, [commandParams,
          resolve: resolve
          reject: reject
        ]

    commandPromise
    .then (result) =>
      @log.debug 'Completed Command', commandName
      resolve result

    .catch (err) ->
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
  query: (queryName, queryParams) ->  new Promise (resolve, reject) =>
    @log.debug 'Got Query', queryName

    if not @_initialized
      err = 'Context not initialized yet'
      @log.error err
      err = new Error err
      reject err
      return

    if not @_queryHandlers[queryName]
      err = "Given query #{queryName} not registered on context"
      @log.error err
      err = new Error err
      return reject err

    if @_queryHandlers[queryName].length <= 1
      queryPromise = @_queryHandlers[queryName].apply @_di, [queryParams]

    else
      queryPromise = new Promise (resolve, reject) =>
        @_queryHandlers[queryName].apply @_di, [queryParams,
          resolve: resolve
          reject: reject
        ]

    queryPromise
    .then (result) =>
      @log.debug "Completed Query #{queryName} with Result #{result}"
      resolve result

    .catch (err) ->
      reject err


module.exports = Context
