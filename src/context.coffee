eventric = require 'eventric'

_           = require './helper/underscore'
async       = require './helper/async'
Repository  = require './repository'
EventBus    = require './event_bus'


class Context

  constructor: (@name) ->
    @_di = {}
    @_params = {}
    @_aggregateRootClasses = {}
    @_adapterClasses = {}
    @_adapterInstances = {}
    @_commandHandlers = {}
    @_queryHandlers = {}
    @_domainEventClasses = {}
    @_domainEventHandlers = {}
    @_projectionClasses = []
    @_projectionInstances = {}
    @_repositoryInstances = {}
    @_domainServices = {}


  ###*
  * @name set
  *
  * @description
  * > Use as: set(key, value)
  * Configure settings for the `context`.
  *
  * @example

     exampleContext.set 'store', StoreAdapter

  *
  * @param {Object} key
  * Available keys are: `store` Eventric Store Adapter
  ###
  set: (key, value) ->
    @_params[key] = value
    @


  ###*
  * @name addDomainEvent
  *
  * @description
  * Adds a DomainEvent Class which will be used when emitting or handling DomainEvents inside of Aggregates, Projectionpr or ProcessManagers
  *
  * @param {String} domainEventName Name of the DomainEvent
  * @param {Function} DomainEventClass DomainEventClass
  ###
  addDomainEvent: (domainEventName, DomainEventClass) ->
    @_domainEventClasses[domainEventName] = DomainEventClass
    @


  addDomainEvents: (domainEventClassesObj) ->
    @addDomainEvent domainEventName, DomainEventClass for domainEventName, DomainEventClass of domainEventClassesObj
    @


  ###*
  * @name addCommandHandler
  *
  * @dscription
  * Use as: addCommandHandler(commandName, commandFunction)
  *
  * Add Commands to the `context`. These will be available to the `command` method after calling `initialize`.
  *
  * @example
    ```javascript
    exampleContext.addCommandHandler('someCommand', function(params, callback) {
      // ...
    });
    ```

  * @param {String} commandName Name of the command
  *
  * @param {String} commandFunction Gets `this.aggregate` dependency injected
  * `this.aggregate.command(params)` Execute command on Aggregate
  *  * `params.name` Name of the Aggregate
  *  * `params.id` Id of the Aggregate
  *  * `params.methodName` MethodName inside the Aggregate
  *  * `params.methodParams` Array of params which the specified AggregateMethod will get as function signature using a [splat](http://stackoverflow.com/questions/6201657/what-does-splats-mean-in-the-coffeescript-tutorial)
  *
  * `this.aggregate.create(params)` Execute command on Aggregate
  *  * `params.name` Name of the Aggregate to be created
  *  * `params.props` Initial properties so be set on the Aggregate or handed to the Aggregates create() method
  ###
  addCommandHandler: (commandHandlerName, commandHandlerFn) ->
    @_commandHandlers[commandHandlerName] = => commandHandlerFn.apply @_di, arguments
    @


  addCommandHandlers: (commandObj) ->
    @addCommandHandler commandHandlerName, commandFunction for commandHandlerName, commandFunction of commandObj
    @


  ###*
  * @name addQueryHandler
  *
  * @dscription
  * Use as: addQueryHandler(queryHandler, queryFunction)
  *
  * Add Commands to the `context`. These will be available to the `query` method after calling `initialize`.
  *
  * @example
    ```javascript
    exampleContext.addQueryHandler('SomeQuery', function(params, callback) {
      // ...
    });
    ```

  * @param {String} queryHandler Name of the query
  *
  * @param {String} queryFunction Function to execute on query
  ###
  addQueryHandler: (queryHandlerName, queryHandlerFn) ->
    @_queryHandlers[queryHandlerName] = => queryHandlerFn.apply @_di, arguments
    @


  addQueryHandlers: (commandObj) ->
    @addQueryHandler queryHandlerName, queryFunction for queryHandlerName, queryFunction of commandObj
    @


  ###*
  * @name addAggregate
  *
  * @description
  *
  * Use as: addAggregate(aggregateName, aggregateDefinition)
  *
  * Add [Aggregates](https://github.com/efacilitation/eventric/wiki/BuildingBlocks#aggregateroot) to the `context`. It takes an AggregateDefinition as argument. The AggregateDefinition must at least consists of one AggregateRoot and can optionally have multiple named AggregateEntities. The Root and Entities itself are completely vanilla since eventric follows the philosophy that your DomainModel-Code should be technology-agnostic.
  *
  * @example

  ```javascript
  exampleContext.addAggregate('Example', {
    root: function(){
      this.doSomething = function(description) {
        // ...
      }
    },
    entities: {
      'ExampleEntityOne': function() {},
      'ExampleEntityTwo': function() {}
    }
  });
  ```
  *
  * @param {String} aggregateName Name of the Aggregate
  * @param {String} aggregateDefinition Definition containing root and entities
  ###
  addAggregate: (aggregateName, AggregateRootClass) ->
    @_aggregateRootClasses[aggregateName] = AggregateRootClass
    @


  addAggregates: (aggregatesObj) ->
    @addAggregate aggregateName, AggregateRootClass for aggregateName, AggregateRootClass of aggregatesObj
    @


  ###*
  *
  * @name addDomainEventHandler
  *
  * @description
  * Use as: addDomainEventHandler(domainEventName, domainEventHandlerFunction)
  *
  * Add handler function which gets called when a specific `DomainEvent` gets triggered
  *
  * @example
    ```javascript
    exampleContext.addDomainEventHandler('Example:create', function(domainEvent) {
      // ...
    });
    ```
  *
  * @param {String} domainEventName Name of the `DomainEvent`
  *
  * @param {Function} Function which gets called with `domainEvent` as argument
  * - `domainEvent` Instance of [[DomainEvent]]
  ###
  addDomainEventHandler: (eventName, handlerFn) ->
    @_domainEventHandlers[eventName] = [] unless @_domainEventHandlers[eventName]
    @_domainEventHandlers[eventName].push => handlerFn.apply @_di, arguments
    @


  addDomainEventHandlers: (domainEventHandlersObj) ->
    @addDomainEventHandler eventName, handlerFn for eventName, handlerFn of domainEventHandlersObj
    @


  ###*
  *
  * @name addDomainService
  *
  * @description
  * Use as: addDomainService(domainServiceName, domainServiceFunction)
  *
  * Add function which gets called when called using $domainService
  *
  * @example
    ```javascript
    exampleContext.addDomainService('DoSomethingSpecial', function(params, callback) {
      // ...
    });
    ```
  *
  * @param {String} domainServiceName Name of the `DomainService`
  *
  * @param {Function} Function which gets called with params as argument
  ###
  addDomainService: (domainServiceName, domainServiceFn) ->
    @_domainServices[domainServiceName] = => domainServiceFn.apply @_di, arguments
    @


  addDomainServices: (domainServiceObjs) ->
    @addDomainService domainServiceName, domainServiceFn for domainServiceName, domainServiceFn of domainServiceObjs
    @


  ###*
  *
  * @name addAdapter
  *
  * @description
  * Use as: addAdapter(adapterName, AdapterClass)
  *
  * Add adapter which get can be used inside of `CommandHandlers`
  *
  * @example
    ```javascript
    exampleContext.addAdapter('SomeAdapter', function() {
      // ...
    });
    ```
  *
  * @param {String} adapterName Name of Adapter
  *
  * @param {Function} Adapter Class
  ###
  addAdapter: (adapterName, adapterClass) ->
    @_adapterClasses[adapterName] = adapterClass
    @


  addAdapters: (adapterObj) ->
    @addAdapter adapterName, fn for adapterName, fn of adapterObj
    @


  ###*
  * @name addProjection
  *
  * @description
  * Add Projection that can subscribe to and handle DomainEvents
  *
  * @param {string} projectionName Name of the Projection
  * @param {Function} The Projection Class definition
  * - define `subscribeToDomainEvents` as Array of DomainEventName Strings
  * - define handle Funtions for DomainEvents by convention: "handleDomainEventName"
  ###
  addProjection: (projectionName, ProjectionClass) ->
    @_projectionClasses.push
      name: projectionName
      class: ProjectionClass
    @


  addProjections: (viewsObj) ->
    @addProjection projectionName, ProjectionClass for projectionName, ProjectionClass of viewsObj
    @


  ###*
  * @name initialize
  *
  * @description
  * Use as: initialize()
  *
  * Initializes the `context` after the `add*` Methods
  *
  * @example
    ```javascript
    exampleContext.initialize(function() {
      // ...
    })
    ```
  ###
  initialize: (callback) ->
    @_eventBus = new EventBus
    @_initializeStore()
    @_initializeRepositories()
    @_initializeAdapters()

    @_di =
      $repository: => @getRepository.apply @, arguments
      $projection: => @getProjection.apply @, arguments
      $adapter: => @getAdapter.apply @, arguments
      $query: => @query.apply @, arguments
      $domainService: =>
        (@getDomainService arguments[0]).apply @, [arguments[1], arguments[2]]
      $projectionStore: (projectionName, callback) =>
        @getProjectionStore projectionName, callback

    @_initializeProjections()
    .then =>
      @_initializeDomainEventHandlers()
      callback()


  _initializeStore: ->
    if @_params.store
      @_store = @_params.store
    else
      globalStore = eventric.get 'store'
      if globalStore
        @_store = globalStore
      else
        @_store = require './store_inmemory'


  _initializeRepositories: ->
    for aggregateName, AggregateRoot of @_aggregateRootClasses
      @_repositoryInstances[aggregateName] = new Repository
        aggregateName: aggregateName
        AggregateRoot: AggregateRoot
        context: @


  _initializeProjections: (callback) ->
    new Promise (resolve, reject) =>
      async.eachSeries @_projectionClasses, (projection, next) =>
        @clearProjectionStore projection.name
        .then =>
          @getProjectionStore projection.name
        .then (projectionStore) =>
          @_initializeProjection projection, projectionStore, =>
            next()

      , (err) =>
        return reject err if err
        resolve()


  _initializeProjection: (projection, projectionStore, callback) ->
    projectionName = projection.name
    ProjectionClass = projection.class
    projection = new ProjectionClass
    for diName, diFn of @_di
      projection[diName] = diFn

    eventNames = []

    for key, value of projection
      if (key.indexOf 'handle') is 0 and (typeof value is 'function')
        eventName = key.replace /^handle/, ''
        eventNames.push eventName

    @_callInitializeOnProjection projection
    .then =>
      @_applyDomainEventsFromStoreToProjection projection, eventNames
    .then =>
      @_subscribeProjectionToDomainEvents projection, eventNames
      @_projectionInstances[projectionName] = projection
      callback()


  _callInitializeOnProjection: (projection) ->
    new Promise (resolve, reject) =>
      resolve projection if not projection.initialize
      projection.initialize =>
        resolve projection


  _applyDomainEventsFromStoreToProjection: (projection, eventNames) ->
    new Promise (resolve, reject) =>
      query = 'name': $in: eventNames

      @_store.find "#{@name}.events", query, (err, events) =>
        async.eachSeries events, (event, next) =>
          @_applyDomainEventToProjection event, projection, =>
            next()

        , (err) =>
          resolve()


  _subscribeProjectionToDomainEvents: (projection, eventNames) ->
    for eventName in eventNames
      @addDomainEventHandler eventName, (domainEvent, done) =>
        @_applyDomainEventToProjection domainEvent, projection


  _applyDomainEventToProjection: (domainEvent, projection, callback=->) =>
    if !projection["handle#{domainEvent.name}"]
      err = new Error "Tried to apply DomainEvent '#{domainEvent.name}' to Projection without a matching handle method"

    else
      projection["handle#{domainEvent.name}"] domainEvent, callback


  _initializeAdapters: ->
    for adapterName, adapterClass of @_adapterClasses
      adapter = new @_adapterClasses[adapterName]
      adapter.initialize?()

      @_adapterInstances[adapterName] = adapter


  _initializeDomainEventHandlers: ->
    for domainEventName, domainEventHandlers of @_domainEventHandlers
      for domainEventHandler in domainEventHandlers
        @_eventBus.subscribeToDomainEvent domainEventName, domainEventHandler


  getProjectionStore: (projectionName, callback) =>
    new Promise (resolve, reject) =>

      @_store.getProjectionStore (@_projectionStoreName projectionName), (err, projectionStore) =>
        callback? err, projectionStore
        return reject err if err
        resolve projectionStore


  clearProjectionStore: (projectionName, callback) =>
    new Promise (resolve, reject) =>
      @_store.clearProjectionStore (@_projectionStoreName projectionName), (err, done) =>
        callback? err, done
        return reject err if err
        resolve done


  _projectionStoreName: (projectionName) =>
    "#{@name}.Projection.#{projectionName}"


  ###*
  * @name getRepository
  *
  * @description Get a Repository for the given aggregateName
  *
  * @param {String} aggregateName Name of the Aggregate
  ###
  getRepository: (aggregateName) ->
    @_repositoryInstances[aggregateName]


  ###*
  * @name getProjection
  *
  * @description Get a Projection Instance after initialize()
  *
  * @param {String} projectionName Name of the Projection
  ###
  getProjection: (projectionName) ->
    @_projectionInstances[projectionName]


  ###*
  * @name getAdapter
  *
  * @description Get a Adapter Instance after initialize()
  *
  * @param {String} adapterName Name of the Adapter
  ###
  getAdapter: (adapterName) ->
    @_adapterInstances[adapterName]


  ###*
  * @name getDomainEvent
  *
  * @description Get a DomainEvent Class after initialize()
  *
  * @param {String} domainEventName Name of the DomainEvent
  ###
  getDomainEvent: (domainEventName) ->
    @_domainEventClasses[domainEventName]


  ###*
  * @name getDomainService
  *
  * @description Get a DomainService after initialize()
  *
  * @param {String} domainServiceName Name of the DomainService
  ###
  getDomainService: (domainServiceName) ->
    @_domainServices[domainServiceName]


  ###*
  * @name getStore
  *
  * @description Get the Store after initialization
  ###
  getStore: ->
    @_store


  ###*
  * @name getEventBus
  *
  * @description Get the EventBus after initialization
  ###
  getEventBus: ->
    @_eventBus


  ###*
  * @name command
  *
  * @description
  *
  * Use as: command(command, callback)
  *
  * Execute previously added `commands`
  *
  * @example
    ```javascript
    exampleContext.command('doSomething',
    function(err, result) {
      // callback
    });
    ```
  *
  * @param {String} `commandName` Name of the CommandHandler to be executed
  * @param {Object} `commandParams` Parameters for the CommandHandler function
  * @param {Function} callback Gets called after the command got executed with the arguments:
  * - `err` null if successful
  * - `result` Set by the `command`
  ###
  command: (commandName, commandParams, callback) ->
    if not callback and typeof commandParams is 'function'
      callback = commandParams

    new Promise (resolve, reject) =>
      if @_commandHandlers[commandName]
        @_commandHandlers[commandName] commandParams, (err, result) =>
          if err
            reject err
          else
            resolve result
          callback? err, result

      else
        err = new Error "Given command #{commandName} not registered on context"
        reject err
        callback? err, null


  ###*
  * @name query
  *
  * @description
  *
  * Use as: query(query, callback)
  *
  * Execute previously added `QueryHandler`
  *
  * @example
    ```javascript
    exampleContext.query('Example', {
        foo: 'bar'
      }
    },
    function(err, result) {
      // callback
    });
    ```
  *
  * @param {String} `queryName` Name of the QueryHandler to be executed
  * @param {Object} `queryParams` Parameters for the QueryHandler function
  * @param {Function} `callback` Callback which gets called after query
  * - `err` null if successful
  * - `result` Set by the `query`
  ###
  query: (queryName, queryParams, callback) ->
    if not callback and typeof queryParams is 'function'
      callback = queryParams

    new Promise (resolve, reject) =>
      if @_queryHandlers[queryName]
        @_queryHandlers[queryName] queryParams, (err, result) =>
          if err
            reject err
          else
            resolve result
          callback? err, result

      else
        err = new Error "Given query #{queryName} not registered on context"
        reject err
        callback? err, null


module.exports = Context
