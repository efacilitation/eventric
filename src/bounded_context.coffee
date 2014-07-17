eventric = require 'eventric'

_           = eventric.require 'HelperUnderscore'
async       = eventric.require 'HelperAsync'
Repository  = eventric.require 'Repository'
EventBus    = eventric.require 'EventBus'


class BoundedContext

  constructor: (@name) ->
    @_di = {}
    @_params = {}
    @_aggregateRootClasses = {}
    @_adapterClasses = {}
    @_adapterInstances = {}
    @_commandHandlers = {}
    @_domainEventClasses = {}
    @_domainEventHandlers = {}
    @_projectionClasses = []
    @_projectionInstances = {}
    @_repositoryInstances = {}


  ###*
  * @name set
  *
  * @description
  * > Use as: set(key, value)
  * Configure settings for the `BoundedContext`.
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
  * Add Commands to the `BoundedContext`. These will be available to the `command` method after calling `initialize`.
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
  * @name addAggregate
  *
  * @description
  *
  * Use as: addAggregate(aggregateName, aggregateDefinition)
  *
  * Add [Aggregates](https://github.com/efacilitation/eventric/wiki/BuildingBlocks#aggregateroot) to the `BoundedContext`. It takes an AggregateDefinition as argument. The AggregateDefinition must at least consists of one AggregateRoot and can optionally have multiple named AggregateEntities. The Root and Entities itself are completely vanilla since eventric follows the philosophy that your DomainModel-Code should be technology-agnostic.
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
  * Initializes the `BoundedContext` after the `add*` Methods
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
    @_initializeProjections()
    .then =>
      @_initializeDomainEventHandlers()

      @_di =
        $repository: => @getRepository.apply @, arguments
        $projection: => @getProjection.apply @, arguments
        $adapter: => @getAdapter.apply @, arguments

      callback()


  _initializeStore: ->
    if @_params.store
      @_store = @_params.store
    else
      globalStore = eventric.get 'store'
      if globalStore
        @_store = globalStore
      else
        throw new Error 'Missing Event Store for Bounded Context'


  _initializeRepositories: ->
    for aggregateName, AggregateRoot of @_aggregateRootClasses
      @_repositoryInstances[aggregateName] = new Repository
        aggregateName: aggregateName
        AggregateRoot: AggregateRoot
        boundedContext: @


  _initializeProjections: (callback) ->
    new Promise (resolve, reject) =>
      async.eachSeries @_projectionClasses, (projection, next) =>
        @_store.collection "#{@name}.Projection.#{projection.name}", (err, collection) =>
          # clear the collection
          # we replay all events the collection subscribed to
          # TODO: store last applied event and go from there
          collection.remove =>
            @_initializeProjection projection.name, projection.class, collection, =>
              next()

      , (err) =>
        return reject err if err
        resolve()


  _initializeProjection: (projectionName, ProjectionClass, collection, callback) ->
    projection = new ProjectionClass
    # TODO: change the injected variable name to "$mongodb, $mysql etc" (@_store.name)
    projection.$store = collection
    projection.$adapter = => @getAdapter.apply @, arguments
    eventNames = []

    for key, value of projection
      if (key.indexOf 'handle') is 0 and (typeof value is 'function')
        eventName = key.replace /^handle/, ''
        eventNames.push eventName

    @_applyDomainEventsFromStoreToProjection projection, eventNames, =>
      @_subscribeProjectionToDomainEvents projection, eventNames
      @_projectionInstances[projectionName] = projection
      callback()


  _applyDomainEventsFromStoreToProjection: (projection, eventNames, callback) ->
    query = 'name': $in: eventNames
    @_store.find "#{@name}.events", query, (err, events) =>
      for event in events
        @_applyDomainEventToProjection event, projection

      callback()


  _subscribeProjectionToDomainEvents: (projection, eventNames) ->
    for eventName in eventNames
      @addDomainEventHandler eventName, (domainEvent) =>
        @_applyDomainEventToProjection domainEvent, projection


  _applyDomainEventToProjection: (domainEvent, projection) ->
    if !projection["handle#{domainEvent.name}"]
      err = new Error "Tried to apply DomainEvent '#{domainEvent.name}' to Projection without a matching handle method"

    else
      projection["handle#{domainEvent.name}"] domainEvent


  _initializeAdapters: ->
    for adapterName, adapterClass of @_adapterClasses
      adapter = new @_adapterClasses[adapterName]
      adapter.initialize?()

      @_adapterInstances[adapterName] = adapter


  _initializeDomainEventHandlers: ->
    for domainEventName, domainEventHandlers of @_domainEventHandlers
      for domainEventHandler in domainEventHandlers
        @_eventBus.subscribeToDomainEvent domainEventName, domainEventHandler


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
    exampleContext.command({
      name: 'doSomething'
    },
    function(err, result) {
      // callback
    });
    ```
  *
  * @param {Object} command Object containing the command definition
  * - `name` The name of the `command`
  * - `params` Object containing parameters. The `command` will get this as first parameter.
  *
  * @param {Function} callback Gets called after the command got executed with the arguments:
  * - `err` null if successful
  * - `result` Set by the `command`
  ###
  command: (command, callback) ->
    new Promise (resolve, reject) =>
      if @_commandHandlers[command.name]
        @_commandHandlers[command.name] command.params, (err, result) =>
          if err
            reject err
          else
            resolve result
          callback? err, result

      else
        err = new Error "Given command #{command.name} not registered on bounded context"
        reject err
        callback? err, null


  ###*
  * @name query
  *
  * @description
  *
  * Use as: query(query, callback)
  *
  * Execute query against a previously added Projection
  *
  * @example
    ```javascript
    exampleContext.query({
      projection: 'Example',
      methodeName: 'getSomething'
    },
    function(err, result) {
      // callback
    });
    ```
  *
  * @param {Object} query Object with the query paramter
  * - `projection` Name of the Projection to query against
  * - `methodName` Name of the method to be executed on the Projection
  * - `methodParams` Parameters for the method
  ###
  query: (query, callback) ->
    new Promise (resolve, reject) =>
      projection = @getProjection query.projectionName
      if not projection
        err = new Error "Given Projection #{query.projectionName} not found on bounded context"
      else if not projection[query.methodName]
        err = new Error "Given method #{query.methodName} not found on Projection #{query.projection}"

      if err
        reject err
        callback? err, null
      else
        projection[query.methodName] query.methodParams, (err, result) =>
          if err
            reject err
          else
            resolve result
          callback? err, result


module.exports = BoundedContext
