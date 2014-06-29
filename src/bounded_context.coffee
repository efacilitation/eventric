eventric = require 'eventric'

_                  = eventric.require 'HelperUnderscore'
AggregateService   = eventric.require 'AggregateService'
EventBus           = eventric.require 'EventBus'


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
    @_readModelClasses = {}
    @_readModelInstances = {}


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
  * Adds a DomainEvent Class which will be used when emitting or handling DomainEvents inside of Aggregates, ReadModels or ProcessManagers
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
  * @name addReadModel
  *
  * @description
  * Add ReadModel that can subscribe to and handle DomainEvents
  *
  * @param {string} readModelName Name of the ReadModel
  * @param {Function} The ReadModel Class definition
  * - define `subscribeToDomainEvents` as Array of DomainEventName Strings
  * - define handle Funtions for DomainEvents by convention: "handleDomainEventName"
  ###
  addReadModel: (readModelName, ReadModelClass) ->
    @_readModelClasses[readModelName] = ReadModelClass
    @


  addReadModels: (viewsObj) ->
    @addReadModel readModelName, ReadModelClass for readModelName, ReadModelClass of viewsObj
    @


  ###*
  * @name initialize
  *
  * @description
  * Use as: initialize(callback)
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
  initialize: ->
    @_initializeStore()
    @_initializeReadModels()
    @_initializeAdapters()

    @_eventBus = new EventBus
    @_initializeDomainEventHandlers()

    @_aggregateService = new AggregateService
    @_aggregateService.initialize @_store, @_eventBus, @
    @_initializeAggregateService()

    @_di =
      $aggregate: @_aggregateService
      $adapter: => @getAdapter.apply @, arguments
      $readmodel: => @getReadModel.apply @, arguments
    @


  _initializeReadModels: ->
    for readModelName, ReadModelClass of @_readModelClasses
      @_initializeReadModel readModelName, ReadModelClass


  _initializeReadModel: (readModelName, ReadModelClass) ->
    @_store.collection "#{@name}.ReadModel.#{readModelName}", (err, collection) =>
      readModel = new ReadModelClass
      # TODO: change the injected variable name to "$mongodb, $mysql etc" (@_store.name)
      readModel.$store = collection
      readModel.$adapter = => @getAdapter.apply @, arguments
      if readModel.subscribeToDomainEvents
        for eventName in readModel.subscribeToDomainEvents
          @_subscribeReadModelToDomainEvent readModel, eventName

      @_readModelInstances[readModelName] = readModel


  _subscribeReadModelToDomainEvent: (readModel, eventName) ->
    @addDomainEventHandler eventName, (domainEvent) =>
      @_applyDomainEventToReadModel domainEvent, readModel


  _applyDomainEventToReadModel: (domainEvent, readModel) ->
    if !readModel["handle#{domainEvent.name}"]
      throw new Error "Tried to apply DomainEvent '#{domainEvent.name}' to ReadModel without a matching handle method"

    else
      readModel["handle#{domainEvent.name}"] domainEvent


  _initializeAdapters: ->
    for adapterName, adapterClass of @_adapterClasses
      adapter = new @_adapterClasses[adapterName]
      adapter.initialize?()

      @_adapterInstances[adapterName] = adapter


  _initializeStore: ->
    if @_params.store
      @_store = @_params.store
    else
      globalStore = eventric.get 'store'
      if globalStore
        @_store = globalStore
      else
        throw new Error 'Missing Event Store for Bounded Context'


  _initializeDomainEventHandlers: ->
    for domainEventName, domainEventHandlers of @_domainEventHandlers
      for domainEventHandler in domainEventHandlers
        @_eventBus.subscribeToDomainEvent domainEventName, domainEventHandler


  _initializeAggregateService: ->
    for aggregateName, AggregateRoot of @_aggregateRootClasses
      @_aggregateService.registerAggregateRoot aggregateName, AggregateRoot


  ###*
  * @name getReadModel
  *
  * @description Get a ReadModel Instance after initialize()
  *
  * @param {String} readModelName Name of the ReadModel
  ###
  getReadModel: (readModelName) ->
    @_readModelInstances[readModelName]


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
  * Execute query against a previously added ReadModel
  *
  * @example
    ```javascript
    exampleContext.query({
      readModel: 'Example',
      methodeName: 'getSomething'
    },
    function(err, result) {
      // callback
    });
    ```
  *
  * @param {Object} query Object with the query paramter
  * - `readModel` Name of the ReadModel to query against
  * - `methodName` Name of the method to be executed on the ReadModel
  * - `methodParams` Parameters for the method
  ###
  query: (query, callback) ->
    new Promise (resolve, reject) =>
      readModel = @getReadModel query.readModel
      if not readModel
        err = new Error "Given ReadModel #{query.readModel} not found on bounded context"
      if not readModel[query.methodName]
        err = new Error "Given method #{query.methodName} not found on ReadModel #{query.readModel}"

      if err
        reject err
        callback? err, null
      else
        readModel[query.methodName] query.methodParams, (err, result) =>
          if err
            reject err
          else
            resolve result
          callback? err, result


module.exports = BoundedContext
