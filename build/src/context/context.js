
/**
* @name Context
* @module Context
* @description
*
* Contexts give you boundaries for parts of your application. You can choose
* the size of such Contexts as you like. Anything from a MicroService to a complete
* application.
 */
var Context,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __slice = [].slice;

Context = (function() {
  function Context(name, _eventric) {
    this.name = name;
    this._eventric = _eventric;
    this.clearProjectionStore = __bind(this.clearProjectionStore, this);
    this.getProjectionStore = __bind(this.getProjectionStore, this);
    this._getAggregateRepository = __bind(this._getAggregateRepository, this);
    this.publishDomainEvent = __bind(this.publishDomainEvent, this);
    this.emitDomainEvent = __bind(this.emitDomainEvent, this);
    this._initialized = false;
    this._params = this._eventric.get();
    this._di = {};
    this._aggregateRootClasses = {};
    this._adapterClasses = {};
    this._adapterInstances = {};
    this._commandHandlers = {};
    this._queryHandlers = {};
    this._domainEventClasses = {};
    this._domainEventHandlers = {};
    this._projectionClasses = {};
    this._domainEventStreamClasses = {};
    this._domainEventStreamInstances = {};
    this._repositoryInstances = {};
    this._domainServices = {};
    this._storeClasses = {};
    this._storeInstances = {};
    this._eventBus = new this._eventric.EventBus(this._eventric);
    this.projectionService = new this._eventric.Projection(this._eventric);
    this.log = this._eventric.log;
  }


  /**
  * @name set
  * @module Context
  * @description Configure Context parameters
  *
  * @example
  
     exampleContext.set 'store', StoreAdapter
  
  *
  * @param {String} key Name of the key
  * @param {Mixed} value Value to be set
   */

  Context.prototype.set = function(key, value) {
    this._params[key] = value;
    return this;
  };


  /**
  * @name get
  * @module Context
  * @description Get configured Context parameters
  *
  * @example
  
     exampleContext.set 'store', StoreAdapter
  
  *
  * @param {String} key Name of the Key
   */

  Context.prototype.get = function(key) {
    return this._params[key];
  };


  /**
  * @name emitDomainEvent
  * @module Context
  * @description Emit Domain Event in the context
  *
  * @param {String} domainEventName Name of the DomainEvent
  * @param {Object} domainEventPayload payload for the DomainEvent
   */

  Context.prototype.emitDomainEvent = function(domainEventName, domainEventPayload) {
    var DomainEventClass, domainEvent;
    DomainEventClass = this.getDomainEvent(domainEventName);
    if (!DomainEventClass) {
      throw new Error("Tried to emitDomainEvent '" + domainEventName + "' which is not defined");
    }
    domainEvent = this._createDomainEvent(domainEventName, DomainEventClass, domainEventPayload);
    return this.getDomainEventsStore().saveDomainEvent(domainEvent, (function(_this) {
      return function() {
        return _this.publishDomainEvent(domainEvent);
      };
    })(this));
  };


  /**
  * @name publishDomainEvent
  * @module Context
  * @description Publish a DomainEvent in the Context
  *
  * @param {Object} domainEvent Instance of a DomainEvent
   */

  Context.prototype.publishDomainEvent = function(domainEvent) {
    return this._eventBus.publishDomainEvent(domainEvent);
  };

  Context.prototype._createDomainEvent = function(domainEventName, DomainEventClass, domainEventPayload) {
    return new this._eventric.DomainEvent({
      id: this._eventric.generateUid(),
      name: domainEventName,
      context: this.name,
      payload: new DomainEventClass(domainEventPayload)
    });
  };


  /**
  * @name addStore
  * @module Context
  * @description Add Store to the Context
  *
  * @param {string} storeName Name of the store
  * @param {Function} StoreClass Class of the store
  * @param {Object} Options to be passed to the store on initialize
   */

  Context.prototype.addStore = function(storeName, StoreClass, storeOptions) {
    if (storeOptions == null) {
      storeOptions = {};
    }
    this._storeClasses[storeName] = {
      Class: StoreClass,
      options: storeOptions
    };
    return this;
  };


  /**
  * @name defineDomainEvent
  * @module Context
  * @description
  * Add a DomainEvent Class which will be used when emitting or
  * handling DomainEvents inside of the Context
  *
  * @param {String} domainEventName Name of the DomainEvent
  * @param {Function} DomainEventClass DomainEventClass
   */

  Context.prototype.defineDomainEvent = function(domainEventName, DomainEventClass) {
    this._domainEventClasses[domainEventName] = DomainEventClass;
    return this;
  };


  /**
  * @name defineDomainEvents
  * @module Context
  * @description Define multiple DomainEvents at once
  *
  * @param {Object} domainEventClassesObj Object containing multiple DomainEventsDefinitions "name: class"
   */

  Context.prototype.defineDomainEvents = function(domainEventClassesObj) {
    var DomainEventClass, domainEventName;
    for (domainEventName in domainEventClassesObj) {
      DomainEventClass = domainEventClassesObj[domainEventName];
      this.defineDomainEvent(domainEventName, DomainEventClass);
    }
    return this;
  };


  /**
  * @name addCommandHandler
  * @module Context
  * @description
  *
  * Add CommandHandlers to the `context`. These will be available to the `command` method
  * after calling `initialize`.
  *
  * @example
    ```javascript
    exampleContext.addCommandHandler('someCommand', function(params, callback) {
      // ...
    });
    ```
  * @param {String} commandName Name of the command
  * @param {String} commandFunction The CommandHandler Function
   */

  Context.prototype.addCommandHandler = function(commandHandlerName, commandHandlerFn) {
    this._commandHandlers[commandHandlerName] = (function(_this) {
      return function() {
        var command, diFn, diFnName, _di, _ref, _ref1;
        command = {
          id: _this._eventric.generateUid(),
          name: commandHandlerName,
          params: (_ref = arguments[0]) != null ? _ref : null
        };
        _di = {};
        _ref1 = _this._di;
        for (diFnName in _ref1) {
          diFn = _ref1[diFnName];
          _di[diFnName] = diFn;
        }
        _di.$aggregate = {
          create: function() {
            var aggregateName, aggregateParams, repository;
            aggregateName = arguments[0], aggregateParams = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
            repository = _this._getAggregateRepository(aggregateName, command);
            return repository.create.apply(repository, aggregateParams);
          },
          load: function(aggregateName, aggregateId) {
            var repository;
            repository = _this._getAggregateRepository(aggregateName, command);
            return repository.findById(aggregateId);
          }
        };
        return commandHandlerFn.apply(_di, arguments);
      };
    })(this);
    return this;
  };

  Context.prototype._getAggregateRepository = function(aggregateName, command) {
    var AggregateRoot, repositoriesCache, repository;
    if (!repositoriesCache) {
      repositoriesCache = {};
    }
    if (!repositoriesCache[aggregateName]) {
      AggregateRoot = this._aggregateRootClasses[aggregateName];
      repository = new this._eventric.Repository({
        aggregateName: aggregateName,
        AggregateRoot: AggregateRoot,
        context: this,
        eventric: this._eventric
      });
      repositoriesCache[aggregateName] = repository;
    }
    repositoriesCache[aggregateName].setCommand(command);
    return repositoriesCache[aggregateName];
  };


  /**
  * @name addCommandHandlers
  * @module Context
  * @description Add multiple CommandHandlers at once
  *
  * @param {Object} commandObj Object containing multiple CommandHandlers "name: class"
   */

  Context.prototype.addCommandHandlers = function(commandObj) {
    var commandFunction, commandHandlerName;
    for (commandHandlerName in commandObj) {
      commandFunction = commandObj[commandHandlerName];
      this.addCommandHandler(commandHandlerName, commandFunction);
    }
    return this;
  };


  /**
  * @name addQueryHandler
  * @module Context
  * @description Add QueryHandler to the `context`
  *
  * @example
    ```javascript
    exampleContext.addQueryHandler('SomeQuery', function(params, callback) {
      // ...
    });
    ```
  
  * @param {String} queryHandler Name of the query
  * @param {String} queryFunction Function to execute on query
   */

  Context.prototype.addQueryHandler = function(queryHandlerName, queryHandlerFn) {
    this._queryHandlers[queryHandlerName] = (function(_this) {
      return function() {
        return queryHandlerFn.apply(_this._di, arguments);
      };
    })(this);
    return this;
  };


  /**
  * @name addQueryHandlers
  * @module Context
  * @description Add multiple QueryHandlers at once
  *
  * @param {Object} queryObj Object containing multiple QueryHandlers "name: class"
   */

  Context.prototype.addQueryHandlers = function(queryObj) {
    var queryFunction, queryHandlerName;
    for (queryHandlerName in queryObj) {
      queryFunction = queryObj[queryHandlerName];
      this.addQueryHandler(queryHandlerName, queryFunction);
    }
    return this;
  };


  /**
  * @name addAggregate
  * @module Context
  * @description Add Aggregates to the `context`
  *
  * @param {String} aggregateName Name of the Aggregate
  * @param {Function} AggregateRootClass AggregateRootClass
   */

  Context.prototype.addAggregate = function(aggregateName, AggregateRootClass) {
    this._aggregateRootClasses[aggregateName] = AggregateRootClass;
    return this;
  };


  /**
  * @name addAggregates
  * @module Context
  * @description Add multiple Aggregates at once
  *
  * @param {Object} aggregatesObj Object containing multiple Aggregates "name: class"
   */

  Context.prototype.addAggregates = function(aggregatesObj) {
    var AggregateRootClass, aggregateName;
    for (aggregateName in aggregatesObj) {
      AggregateRootClass = aggregatesObj[aggregateName];
      this.addAggregate(aggregateName, AggregateRootClass);
    }
    return this;
  };


  /**
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
   */

  Context.prototype.subscribeToDomainEvent = function(domainEventName, handlerFn, options) {
    var domainEventHandler;
    if (options == null) {
      options = {};
    }
    domainEventHandler = (function(_this) {
      return function() {
        return handlerFn.apply(_this._di, arguments);
      };
    })(this);
    return this._eventBus.subscribeToDomainEvent(domainEventName, domainEventHandler, options);
  };


  /**
  * @name subscribeToDomainEvents
  * @module Context
  * @description Add multiple DomainEventSubscribers at once
  *
  * @param {Object} domainEventHandlersObj Object containing multiple Subscribers "name: handlerFn"
   */

  Context.prototype.subscribeToDomainEvents = function(domainEventHandlersObj) {
    var domainEventName, handlerFn, _results;
    _results = [];
    for (domainEventName in domainEventHandlersObj) {
      handlerFn = domainEventHandlersObj[domainEventName];
      _results.push(this.subscribeToDomainEvent(domainEventName, handlerFn));
    }
    return _results;
  };


  /**
  * @name subscribeToDomainEventWithAggregateId
  * @module Context
  * @description Add handler function which gets called when a specific `DomainEvent` containing a specific AggregateId gets triggered
  *
  * @param {String} domainEventName Name of the `DomainEvent`
  * @param {String} aggregateId AggregateId
  * @param {Function} Function which gets called with `domainEvent` as argument
  * @param {Object} options Options to set on the EventBus ("async: false" is default)
   */

  Context.prototype.subscribeToDomainEventWithAggregateId = function(domainEventName, aggregateId, handlerFn, options) {
    var domainEventHandler;
    if (options == null) {
      options = {};
    }
    domainEventHandler = (function(_this) {
      return function() {
        return handlerFn.apply(_this._di, arguments);
      };
    })(this);
    return this._eventBus.subscribeToDomainEventWithAggregateId(domainEventName, aggregateId, domainEventHandler, options);
  };


  /**
  * @name subscribeToAllDomainEvents
  * @module Context
  * @description Add handler function which gets called when any `DomainEvent` gets triggered
  *
  * @param {Function} Function which gets called with `domainEvent` as argument
  * @param {Object} options Options to set on the EventBus ("async: false" is default)
   */

  Context.prototype.subscribeToAllDomainEvents = function(handlerFn, options) {
    var domainEventHandler;
    if (options == null) {
      options = {};
    }
    domainEventHandler = (function(_this) {
      return function() {
        return handlerFn.apply(_this._di, arguments);
      };
    })(this);
    return this._eventBus.subscribeToAllDomainEvents(domainEventHandler, options);
  };


  /**
  * @name subscribeToDomainEventStream
  * @module Context
  * @description Add DomainEventStream Definition
  *
  * @param {String} domainEventStreamName Name of the DomainEventStream
  * @param {Function} DomainEventStream Definition
  * @param {Object} Options to be used when initializing the DomainEventStream
   */

  Context.prototype.subscribeToDomainEventStream = function(domainEventStreamName, handlerFn, options) {
    var domainEventName, domainEventNames, domainEventStream, domainEventStreamId, err, functionName, functionValue;
    if (options == null) {
      options = {};
    }
    if (!this._domainEventStreamClasses[domainEventStreamName]) {
      err = "DomainEventStream Class with name " + domainEventStreamName + " not added";
      return this.log.error(err);
    }
    domainEventStream = new this._domainEventStreamClasses[domainEventStreamName];
    domainEventStream._domainEventsPublished = {};
    domainEventStreamId = this._eventric.generateUid();
    this._domainEventStreamInstances[domainEventStreamId] = domainEventStream;
    domainEventNames = [];
    for (functionName in domainEventStream) {
      functionValue = domainEventStream[functionName];
      if ((functionName.indexOf('filter')) === 0 && (typeof functionValue === 'function')) {
        domainEventName = functionName.replace(/^filter/, '');
        domainEventNames.push(domainEventName);
      }
    }
    this._applyDomainEventsFromStoreToDomainEventStream(domainEventNames, domainEventStream, handlerFn).then((function(_this) {
      return function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = domainEventNames.length; _i < _len; _i++) {
          domainEventName = domainEventNames[_i];
          _results.push(_this.subscribeToDomainEvent(domainEventName, function(domainEvent) {
            if (domainEventStream._domainEventsPublished[domainEvent.id]) {
              return;
            }
            if ((domainEventStream["filter" + domainEvent.name](domainEvent)) === true) {
              return handlerFn(domainEvent, function() {});
            }
          }, options));
        }
        return _results;
      };
    })(this));
    return domainEventStreamId;
  };

  Context.prototype._applyDomainEventsFromStoreToDomainEventStream = function(eventNames, domainEventStream) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.findDomainEventsByName(eventNames).then(function(domainEvents) {
          if (!domainEvents || domainEvents.length === 0) {
            return resolve(eventNames);
          }
          return _this._eventric.eachSeries(domainEvents, function(domainEvent, next) {
            if ((domainEventStream["filter" + domainEvent.name](domainEvent)) === true) {
              handlerFn(domainEvent, function() {});
              domainEventStream._domainEventsPublished[domainEvent.id] = true;
              return next();
            }
          }, function(err) {
            if (err) {
              return reject(err);
            }
            return resolve(eventNames);
          });
        })["catch"](function(err) {
          return reject(err);
        });
      };
    })(this));
  };


  /**
  * @name addDomainService
  * @module Context
  * @description Add function which gets called when called using $domainService
  *
  * @example
    ```javascript
    exampleContext.addDomainService('DoSomethingSpecial', function(params, callback) {
      // ...
    });
    ```
  *
  * @param {String} domainServiceName Name of the `DomainService`
  * @param {Function} Function which gets called with params as argument
   */

  Context.prototype.addDomainService = function(domainServiceName, domainServiceFn) {
    this._domainServices[domainServiceName] = (function(_this) {
      return function() {
        return domainServiceFn.apply(_this._di, arguments);
      };
    })(this);
    return this;
  };


  /**
  * @name addDomainServices
  * @module Context
  * @description Add multiple DomainServices at once
  *
  * @param {Object} domainServiceObjs Object containing multiple DomainEventStreamDefinitions "name: definition"
   */

  Context.prototype.addDomainServices = function(domainServiceObjs) {
    var domainServiceFn, domainServiceName;
    for (domainServiceName in domainServiceObjs) {
      domainServiceFn = domainServiceObjs[domainServiceName];
      this.addDomainService(domainServiceName, domainServiceFn);
    }
    return this;
  };


  /**
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
   */

  Context.prototype.addAdapter = function(adapterName, adapterClass) {
    this._adapterClasses[adapterName] = adapterClass;
    return this;
  };


  /**
  * @name addAdapters
  * @module Context
  * @description Add multiple Adapters at once
  *
  * @param {Object} adaptersObj Object containing multiple Adapters "name: function"
   */

  Context.prototype.addAdapters = function(adaptersObj) {
    var adapterName, fn;
    for (adapterName in adaptersObj) {
      fn = adaptersObj[adapterName];
      this.addAdapter(adapterName, fn);
    }
    return this;
  };


  /**
  * @name addProjection
  * @module Context
  * @description Add Projection that can subscribe to and handle DomainEvents
  *
  * @param {string} projectionName Name of the Projection
  * @param {Function} The Projection Class definition
   */

  Context.prototype.addProjection = function(projectionName, ProjectionClass) {
    this._projectionClasses[projectionName] = ProjectionClass;
    return this;
  };


  /**
  * @name addProjections
  * @module Context
  * @description Add multiple Projections at once
  *
  * @param {object} Projections key projectionName, value ProjectionClass
   */

  Context.prototype.addProjections = function(viewsObj) {
    var ProjectionClass, projectionName;
    for (projectionName in viewsObj) {
      ProjectionClass = viewsObj[projectionName];
      this.addProjection(projectionName, ProjectionClass);
    }
    return this;
  };


  /**
  * @name addDomainEventStream
  * @module Context
  * @description Add DomainEventStream which projections can subscribe to
  *
  * @param {string} domainEventStreamName Name of the Stream
  * @param {Function} The DomainEventStream Class definition
   */

  Context.prototype.addDomainEventStream = function(domainEventStreamName, DomainEventStreamClass) {
    this._domainEventStreamClasses[domainEventStreamName] = DomainEventStreamClass;
    return this;
  };


  /**
  * @name addDomainEventStreams
  * @module Context
  * @description Add multiple DomainEventStreams at once
  *
  * @param {object} DomainEventStreams key domainEventStreamName, value DomainEventStreamClass
   */

  Context.prototype.addDomainEventStreams = function(viewsObj) {
    var DomainEventStreamClass, domainEventStreamName;
    for (domainEventStreamName in viewsObj) {
      DomainEventStreamClass = viewsObj[domainEventStreamName];
      this.addDomainEventStream(domainEventStreamName, DomainEventStreamClass);
    }
    return this;
  };


  /**
  * @name getProjectionInstance
  * @module Context
  * @description Get ProjectionInstance
  *
  * @param {String} projectionId ProjectionId
   */

  Context.prototype.getProjectionInstance = function(projectionId) {
    return this.projectionService.getInstance(projectionId);
  };


  /**
  * @name destroyProjectionInstance
  * @module Context
  * @description Destroy a ProjectionInstance
  *
  * @param {String} projectionId ProjectionId
   */

  Context.prototype.destroyProjectionInstance = function(projectionId) {
    return this.projectionService.destroyInstance(projectionId, this);
  };


  /**
  * @name initializeProjectionInstance
  * @module Context
  * @description Initialize a ProjectionInstance
  *
  * @param {String} projectionName Name of the Projection
  * @param {Object} params Object containing Projection Parameters
   */

  Context.prototype.initializeProjectionInstance = function(projectionName, params) {
    var err;
    if (!this._projectionClasses[projectionName]) {
      err = "Given projection " + projectionName + " not registered on context";
      this._eventric.log.error(err);
      err = new Error(err);
      return err;
    }
    return this.projectionService.initializeInstance(projectionName, this._projectionClasses[projectionName], params, this);
  };


  /**
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
   */

  Context.prototype.initialize = function(callback) {
    if (callback == null) {
      callback = function() {};
    }
    return new Promise((function(_this) {
      return function(resolve, reject) {
        _this.log.debug("[" + _this.name + "] Initializing");
        _this.log.debug("[" + _this.name + "] Initializing Store");
        return _this._initializeStores().then(function() {
          _this.log.debug("[" + _this.name + "] Finished initializing Store");
          _this._di = {
            $adapter: function() {
              return _this.getAdapter.apply(_this, arguments);
            },
            $query: function() {
              return _this.query.apply(_this, arguments);
            },
            $domainService: function() {
              return (_this.getDomainService(arguments[0])).apply(_this, [arguments[1], arguments[2]]);
            },
            $projectionStore: function() {
              return _this.getProjectionStore.apply(_this, arguments);
            },
            $emitDomainEvent: function() {
              return _this.emitDomainEvent.apply(_this, arguments);
            }
          };
          _this.log.debug("[" + _this.name + "] Initializing Adapters");
          return _this._initializeAdapters();
        }).then(function() {
          _this.log.debug("[" + _this.name + "] Finished initializing Adapters");
          _this.log.debug("[" + _this.name + "] Initializing Projections");
          return _this._initializeProjections();
        }).then(function() {
          _this.log.debug("[" + _this.name + "] Finished initializing Projections");
          _this.log.debug("[" + _this.name + "] Finished initializing");
          _this._initialized = true;
          callback();
          return resolve();
        })["catch"](function(err) {
          callback(err);
          return reject(err);
        });
      };
    })(this));
  };

  Context.prototype._initializeStores = function() {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var store, storeName, stores, _ref;
        stores = [];
        _ref = _this._eventric.defaults(_this._storeClasses, _this._eventric.getStores());
        for (storeName in _ref) {
          store = _ref[storeName];
          stores.push({
            name: storeName,
            Class: store.Class,
            options: store.options
          });
        }
        return _this._eventric.eachSeries(stores, function(store, next) {
          _this.log.debug("[" + _this.name + "] Initializing Store " + store.name);
          _this._storeInstances[store.name] = new store.Class;
          return _this._storeInstances[store.name].initialize(_this, store.options, function() {
            _this.log.debug("[" + _this.name + "] Finished initializing Store " + store.name);
            return next();
          });
        }, function(err) {
          if (err) {
            return reject(err);
          }
          return resolve();
        });
      };
    })(this));
  };

  Context.prototype._initializeProjections = function() {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var ProjectionClass, projectionName, projections, _ref;
        projections = [];
        _ref = _this._projectionClasses;
        for (projectionName in _ref) {
          ProjectionClass = _ref[projectionName];
          projections.push({
            name: projectionName,
            "class": ProjectionClass
          });
        }
        return _this._eventric.eachSeries(projections, function(projection, next) {
          var eventNames;
          eventNames = null;
          _this.log.debug("[" + _this.name + "] Initializing Projection " + projection.name);
          return _this.projectionService.initializeInstance(projection.name, projection["class"], {}, _this).then(function(projectionId) {
            _this.log.debug("[" + _this.name + "] Finished initializing Projection " + projection.name);
            return next();
          })["catch"](function(err) {
            return reject(err);
          });
        }, function(err) {
          if (err) {
            return reject(err);
          }
          return resolve();
        });
      };
    })(this));
  };

  Context.prototype._initializeAdapters = function() {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var adapter, adapterClass, adapterName, _ref;
        _ref = _this._adapterClasses;
        for (adapterName in _ref) {
          adapterClass = _ref[adapterName];
          adapter = new _this._adapterClasses[adapterName];
          if (typeof adapter.initialize === "function") {
            adapter.initialize();
          }
          _this._adapterInstances[adapterName] = adapter;
        }
        return resolve();
      };
    })(this));
  };


  /**
  * @name getProjection
  * @module Context
  * @description Get a Projection Instance after initialize()
  *
  * @param {String} projectionName Name of the Projection
   */

  Context.prototype.getProjection = function(projectionId) {
    return this.projectionService.getInstance(projectionId);
  };


  /**
  * @name getAdapter
  * @module Context
  * @description Get a Adapter Instance after initialize()
  *
  * @param {String} adapterName Name of the Adapter
   */

  Context.prototype.getAdapter = function(adapterName) {
    return this._adapterInstances[adapterName];
  };


  /**
  * @name getDomainEvent
  * @module Context
  * @description Get a DomainEvent Class after initialize()
  *
  * @param {String} domainEventName Name of the DomainEvent
   */

  Context.prototype.getDomainEvent = function(domainEventName) {
    return this._domainEventClasses[domainEventName];
  };


  /**
  * @name getDomainService
  * @module Context
  * @description Get a DomainService after initialize()
  *
  * @param {String} domainServiceName Name of the DomainService
   */

  Context.prototype.getDomainService = function(domainServiceName) {
    return this._domainServices[domainServiceName];
  };


  /**
  * @name getDomainEventsStore
  * @module Context
  * @description Get the current default DomainEventsStore
   */

  Context.prototype.getDomainEventsStore = function() {
    var storeName;
    storeName = this.get('default domain events store');
    return this._storeInstances[storeName];
  };


  /**
  * @name saveDomainEvent
  * @module Context
  * @description Save a DomainEvent to the default DomainEventStore
  *
  * @param {Object} domainEvent Instance of a DomainEvent
   */

  Context.prototype.saveDomainEvent = function(domainEvent) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.getDomainEventsStore().saveDomainEvent(domainEvent, function(err, events) {
          _this.publishDomainEvent(domainEvent);
          if (err) {
            return reject(err);
          }
          return resolve(events);
        });
      };
    })(this));
  };


  /**
  * @name findAllDomainEvents
  * @module Context
  * @description Return all DomainEvents from the default DomainEventStore
   */

  Context.prototype.findAllDomainEvents = function() {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.getDomainEventsStore().findAllDomainEvents(function(err, events) {
          if (err) {
            return reject(err);
          }
          return resolve(events);
        });
      };
    })(this));
  };


  /**
  * @name findDomainEventsByName
  * @module Context
  * @description Return DomainEvents from the default DomainEventStore which match the given DomainEventName
  *
  * @param {String} domainEventName Name of the DomainEvent to be returned
   */

  Context.prototype.findDomainEventsByName = function() {
    var findArguments;
    findArguments = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var _ref;
        return (_ref = _this.getDomainEventsStore()).findDomainEventsByName.apply(_ref, __slice.call(findArguments).concat([function(err, events) {
          if (err) {
            return reject(err);
          }
          return resolve(events);
        }]));
      };
    })(this));
  };


  /**
  * @name findDomainEventsByAggregateId
  * @module Context
  * @description Return DomainEvents from the default DomainEventStore which match the given AggregateId
  *
  * @param {String} aggregateId AggregateId of the DomainEvents to be found
   */

  Context.prototype.findDomainEventsByAggregateId = function() {
    var findArguments;
    findArguments = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var _ref;
        return (_ref = _this.getDomainEventsStore()).findDomainEventsByAggregateId.apply(_ref, __slice.call(findArguments).concat([function(err, events) {
          if (err) {
            return reject(err);
          }
          return resolve(events);
        }]));
      };
    })(this));
  };


  /**
  * @name findDomainEventsByNameAndAggregateId
  * @module Context
  * @description Return DomainEvents from the default DomainEventStore which match the given DomainEventName and AggregateId
  *
  * @param {String} domainEventName Name of the DomainEvents to be found
  * @param {String} aggregateId AggregateId of the DomainEvents to be found
   */

  Context.prototype.findDomainEventsByNameAndAggregateId = function() {
    var findArguments;
    findArguments = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var _ref;
        return (_ref = _this.getDomainEventsStore()).findDomainEventsByNameAndAggregateId.apply(_ref, __slice.call(findArguments).concat([function(err, events) {
          if (err) {
            return reject(err);
          }
          return resolve(events);
        }]));
      };
    })(this));
  };


  /**
  * @name findDomainEventsByAggregateName
  * @module Context
  * @description Return DomainEvents from the default DomainEventStore which match the given AggregateName
  *
  * @param {String} aggregateName AggregateName of the DomainEvents to be found
   */

  Context.prototype.findDomainEventsByAggregateName = function() {
    var findArguments;
    findArguments = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var _ref;
        return (_ref = _this.getDomainEventsStore()).findDomainEventsByAggregateName.apply(_ref, __slice.call(findArguments).concat([function(err, events) {
          if (err) {
            return reject(err);
          }
          return resolve(events);
        }]));
      };
    })(this));
  };


  /**
  * @name getProjectionStore
  * @module Context
  * @description Get a specific ProjectionStore Instance
  *
  * @param {String} storeName Name of the Store
  * @param {String} projectionName Name of the Projection
   */

  Context.prototype.getProjectionStore = function(storeName, projectionName, callback) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var err;
        if (!_this._storeInstances[storeName]) {
          err = "Requested Store with name " + storeName + " not found";
          _this.log.error(err);
          if (typeof callback === "function") {
            callback(err, null);
          }
          return reject(err);
        }
        return _this._storeInstances[storeName].getProjectionStore(projectionName, function(err, projectionStore) {
          if (typeof callback === "function") {
            callback(err, projectionStore);
          }
          if (err) {
            return reject(err);
          }
          return resolve(projectionStore);
        });
      };
    })(this));
  };


  /**
  * @name clearProjectionStore
  * @module Context
  * @description Clear the ProjectionStore
  *
  * @param {String} storeName Name of the Store
  * @param {String} projectionName Name of the Projection
   */

  Context.prototype.clearProjectionStore = function(storeName, projectionName, callback) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var err;
        if (!_this._storeInstances[storeName]) {
          err = "Requested Store with name " + storeName + " not found";
          _this.log.error(err);
          if (typeof callback === "function") {
            callback(err, null);
          }
          return reject(err);
        }
        return _this._storeInstances[storeName].clearProjectionStore(projectionName, function(err, done) {
          if (typeof callback === "function") {
            callback(err, done);
          }
          if (err) {
            return reject(err);
          }
          return resolve(done);
        });
      };
    })(this));
  };


  /**
  * @name getEventBus
  * @module Context
  * @description Get the EventBus
   */

  Context.prototype.getEventBus = function() {
    return this._eventBus;
  };


  /**
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
   */

  Context.prototype.command = function(commandName, commandParams) {
    this.log.debug('Got Command', commandName);
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var err;
        if (!_this._initialized) {
          err = 'Context not initialized yet';
          _this.log.error(err);
          err = new Error(err);
          return reject(err);
        }
        if (_this._commandHandlers[commandName]) {
          return _this._commandHandlers[commandName](commandParams, function(err, result) {
            _this.log.debug('Completed Command', commandName);
            return _this._eventric.nextTick(function() {
              if (err) {
                return reject(err);
              } else {
                return resolve(result);
              }
            });
          });
        } else {
          err = "Given command " + commandName + " not registered on context";
          _this.log.error(err);
          err = new Error(err);
          return reject(err);
        }
      };
    })(this));
  };


  /**
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
   */

  Context.prototype.query = function(queryName, queryParams) {
    this.log.debug('Got Query', queryName);
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var err;
        if (!_this._initialized) {
          err = 'Context not initialized yet';
          _this.log.error(err);
          err = new Error(err);
          reject(err);
          return;
        }
        if (_this._queryHandlers[queryName]) {
          return _this._queryHandlers[queryName](queryParams, function(err, result) {
            _this.log.debug('Completed Query', queryName);
            return _this._eventric.nextTick(function() {
              if (err) {
                return reject(err);
              } else {
                return resolve(result);
              }
            });
          });
        } else {
          err = "Given query " + queryName + " not registered on context";
          _this.log.error(err);
          err = new Error(err);
          return reject(err);
        }
      };
    })(this));
  };


  /**
  * @name enableWaitingMode
  * @module Context
  * @description Enables the WaitingMode
   */

  Context.prototype.enableWaitingMode = function() {
    return this.set('waiting mode', true);
  };


  /**
  * @name disableWaitingMode
  * @module Context
  * @description Disables the WaitingMode
   */

  Context.prototype.disableWaitingMode = function() {
    return this.set('waiting mode', false);
  };


  /**
  * @name isWaitingModeEnabled
  * @module Context
  * @description Returns if the WaitingMode is enabled
   */

  Context.prototype.isWaitingModeEnabled = function() {
    return this.get('waiting mode');
  };

  return Context;

})();

module.exports = Context;
