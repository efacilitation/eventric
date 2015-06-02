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
    this.emitDomainEvent = __bind(this.emitDomainEvent, this);
    this._initialized = false;
    this._params = this._eventric.get();
    this._di = {};
    this._aggregateRootClasses = {};
    this._commandHandlers = {};
    this._queryHandlers = {};
    this._domainEventClasses = {};
    this._domainEventHandlers = {};
    this._projectionClasses = {};
    this._domainEventStreamClasses = {};
    this._domainEventStreamInstances = {};
    this._repositoryInstances = {};
    this._storeClasses = {};
    this._storeInstances = {};
    this._eventBus = new this._eventric.EventBus(this._eventric);
    this.projectionService = new this._eventric.Projection(this._eventric, this);
    this.log = this._eventric.log;
  }

  Context.prototype.set = function(key, value) {
    this._params[key] = value;
    return this;
  };

  Context.prototype.get = function(key) {
    return this._params[key];
  };

  Context.prototype.emitDomainEvent = function(domainEventName, domainEventPayload) {
    var DomainEventClass, domainEvent;
    DomainEventClass = this.getDomainEvent(domainEventName);
    if (!DomainEventClass) {
      throw new Error("Tried to emitDomainEvent '" + domainEventName + "' which is not defined");
    }
    domainEvent = this.createDomainEvent(domainEventName, DomainEventClass, domainEventPayload);
    return this.saveAndPublishDomainEvent(domainEvent).then((function(_this) {
      return function() {
        return _this.log.debug("Created and Handled DomainEvent in Context", domainEvent);
      };
    })(this));
  };

  Context.prototype.createDomainEvent = function(domainEventName, DomainEventClass, domainEventPayload, aggregate) {
    var payload;
    payload = {};
    DomainEventClass.apply(payload, [domainEventPayload]);
    return new this._eventric.DomainEvent({
      id: this._eventric.generateUid(),
      name: domainEventName,
      aggregate: aggregate,
      context: this.name,
      payload: payload
    });
  };

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

  Context.prototype.defineDomainEvent = function(domainEventName, DomainEventClass) {
    this._domainEventClasses[domainEventName] = DomainEventClass;
    return this;
  };

  Context.prototype.defineDomainEvents = function(domainEventClassesObj) {
    var DomainEventClass, domainEventName;
    for (domainEventName in domainEventClassesObj) {
      DomainEventClass = domainEventClassesObj[domainEventName];
      this.defineDomainEvent(domainEventName, DomainEventClass);
    }
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

  Context.prototype.addCommandHandlers = function(commands) {
    var commandFunction, commandHandlerName;
    for (commandHandlerName in commands) {
      commandFunction = commands[commandHandlerName];
      this._commandHandlers[commandHandlerName] = commandFunction;
    }
    return this;
  };

  Context.prototype.addQueryHandlers = function(queries) {
    var queryFunction, queryHandlerName;
    for (queryHandlerName in queries) {
      queryFunction = queries[queryHandlerName];
      this._queryHandlers[queryHandlerName] = queryFunction;
    }
    return this;
  };

  Context.prototype.addAggregate = function(aggregateName, AggregateRootClass) {
    this._aggregateRootClasses[aggregateName] = AggregateRootClass;
    return this;
  };

  Context.prototype.subscribeToDomainEvent = function(domainEventName, handlerFn) {
    var domainEventHandler;
    domainEventHandler = (function(_this) {
      return function() {
        return handlerFn.apply(_this._di, arguments);
      };
    })(this);
    return this._eventBus.subscribeToDomainEvent(domainEventName, domainEventHandler);
  };

  Context.prototype.subscribeToDomainEvents = function(domainEventHandlersObj) {
    var domainEventName, handlerFn, _results;
    _results = [];
    for (domainEventName in domainEventHandlersObj) {
      handlerFn = domainEventHandlersObj[domainEventName];
      _results.push(this.subscribeToDomainEvent(domainEventName, handlerFn));
    }
    return _results;
  };

  Context.prototype.subscribeToDomainEventWithAggregateId = function(domainEventName, aggregateId, handlerFn) {
    var domainEventHandler;
    domainEventHandler = (function(_this) {
      return function() {
        return handlerFn.apply(_this._di, arguments);
      };
    })(this);
    return this._eventBus.subscribeToDomainEventWithAggregateId(domainEventName, aggregateId, domainEventHandler);
  };

  Context.prototype.subscribeToAllDomainEvents = function(handlerFn) {
    var domainEventHandler;
    domainEventHandler = (function(_this) {
      return function() {
        return handlerFn.apply(_this._di, arguments);
      };
    })(this);
    return this._eventBus.subscribeToAllDomainEvents(domainEventHandler);
  };

  Context.prototype.addProjection = function(projectionName, ProjectionClass) {
    this._projectionClasses[projectionName] = ProjectionClass;
    return this;
  };

  Context.prototype.addProjections = function(viewsObj) {
    var ProjectionClass, projectionName;
    for (projectionName in viewsObj) {
      ProjectionClass = viewsObj[projectionName];
      this.addProjection(projectionName, ProjectionClass);
    }
    return this;
  };

  Context.prototype.getProjectionInstance = function(projectionId) {
    return this.projectionService.getInstance(projectionId);
  };

  Context.prototype.destroyProjectionInstance = function(projectionId) {
    return this.projectionService.destroyInstance(projectionId, this);
  };

  Context.prototype.initializeProjectionInstance = function(projectionName, params) {
    var err;
    if (!this._projectionClasses[projectionName]) {
      err = "Given projection " + projectionName + " not registered on context";
      this.log.error(err);
      err = new Error(err);
      return err;
    }
    return this.projectionService.initializeInstance(projectionName, this._projectionClasses[projectionName], params);
  };

  Context.prototype.initialize = function() {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        _this.log.debug("[" + _this.name + "] Initializing");
        _this.log.debug("[" + _this.name + "] Initializing Store");
        return _this._initializeStores().then(function() {
          _this.log.debug("[" + _this.name + "] Finished initializing Store");
          return _this._di = {
            $query: function() {
              return _this.query.apply(_this, arguments);
            },
            $projectionStore: function() {
              return _this.getProjectionStore.apply(_this, arguments);
            },
            $emitDomainEvent: function() {
              return _this.emitDomainEvent.apply(_this, arguments);
            }
          };
        }).then(function() {
          _this.log.debug("[" + _this.name + "] Initializing Projections");
          return _this._initializeProjections();
        }).then(function() {
          _this.log.debug("[" + _this.name + "] Finished initializing Projections");
          _this.log.debug("[" + _this.name + "] Finished initializing");
          _this._initialized = true;
          return resolve();
        })["catch"](function(err) {
          return reject(err);
        });
      };
    })(this));
  };

  Context.prototype._initializeStores = function() {
    var promise, store, storeName, stores, _ref;
    stores = [];
    _ref = this._eventric.defaults(this._storeClasses, this._eventric.getStores());
    for (storeName in _ref) {
      store = _ref[storeName];
      stores.push({
        name: storeName,
        Class: store.Class,
        options: store.options
      });
    }
    promise = new Promise(function(resolve) {
      return resolve();
    });
    stores.forEach((function(_this) {
      return function(store) {
        _this.log.debug("[" + _this.name + "] Initializing Store " + store.name);
        _this._storeInstances[store.name] = new store.Class;
        return promise = promise.then(function() {
          return _this._storeInstances[store.name].initialize(_this, store.options);
        }).then(function() {
          return _this.log.debug("[" + _this.name + "] Finished initializing Store " + store.name);
        });
      };
    })(this));
    return promise;
  };

  Context.prototype._initializeProjections = function() {
    var ProjectionClass, projectionName, projections, promise, _ref;
    promise = new Promise(function(resolve) {
      return resolve();
    });
    projections = [];
    _ref = this._projectionClasses;
    for (projectionName in _ref) {
      ProjectionClass = _ref[projectionName];
      projections.push({
        name: projectionName,
        "class": ProjectionClass
      });
    }
    projections.forEach((function(_this) {
      return function(projection) {
        var eventNames;
        eventNames = null;
        _this.log.debug("[" + _this.name + "] Initializing Projection " + projection.name);
        return promise = promise.then(function() {
          return _this.projectionService.initializeInstance(projection.name, projection["class"], {});
        }).then(function(projectionId) {
          return _this.log.debug("[" + _this.name + "] Finished initializing Projection " + projection.name);
        });
      };
    })(this));
    return promise;
  };

  Context.prototype.getProjection = function(projectionId) {
    return this.projectionService.getInstance(projectionId);
  };

  Context.prototype.getDomainEvent = function(domainEventName) {
    return this._domainEventClasses[domainEventName];
  };

  Context.prototype.getDomainEventsStore = function() {
    var storeName;
    storeName = this.get('default domain events store');
    return this._storeInstances[storeName];
  };

  Context.prototype.saveAndPublishDomainEvent = function(domainEvent) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        return _this.getDomainEventsStore().saveDomainEvent(domainEvent).then(function() {
          return _this.publishDomainEvent(domainEvent);
        }).then(function(err) {
          if (err) {
            return reject(err);
          }
          return resolve(domainEvent);
        });
      };
    })(this));
  };

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

  Context.prototype.getProjectionStore = function(storeName, projectionName) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var err;
        if (!_this._storeInstances[storeName]) {
          err = "Requested Store with name " + storeName + " not found";
          _this.log.error(err);
          return reject(err);
        }
        return _this._storeInstances[storeName].getProjectionStore(projectionName).then(function(projectionStore) {
          return resolve(projectionStore);
        })["catch"](function(err) {
          return reject(err);
        });
      };
    })(this));
  };

  Context.prototype.clearProjectionStore = function(storeName, projectionName) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var err;
        if (!_this._storeInstances[storeName]) {
          err = "Requested Store with name " + storeName + " not found";
          _this.log.error(err);
          return reject(err);
        }
        return _this._storeInstances[storeName].clearProjectionStore(projectionName).then(function() {
          return resolve();
        })["catch"](function(err) {
          return reject(err);
        });
      };
    })(this));
  };

  Context.prototype.getEventBus = function() {
    return this._eventBus;
  };

  Context.prototype.command = function(commandName, params) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var command, commandHandlerFn, diFn, diFnName, err, executeCommand, _di, _ref;
        command = {
          id: _this._eventric.generateUid(),
          name: commandName,
          params: params
        };
        _this.log.debug('Got Command', command);
        _this._verifyContextIsInitialized(commandName);
        if (!_this._commandHandlers[commandName]) {
          err = "Given command " + commandName + " not registered on context";
          _this.log.error(err);
          err = new Error(err);
          return reject(err);
        }
        _di = {};
        _ref = _this._di;
        for (diFnName in _ref) {
          diFn = _ref[diFnName];
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
        executeCommand = null;
        commandHandlerFn = _this._commandHandlers[commandName];
        executeCommand = commandHandlerFn.apply(_di, [params]);
        return Promise.all([executeCommand]).then(function(_arg) {
          var result;
          result = _arg[0];
          _this.log.debug('Completed Command', commandName);
          return resolve(result);
        })["catch"](function(error) {
          return reject(error);
        });
      };
    })(this));
  };

  Context.prototype.query = function(queryName, params) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var err, executeQuery;
        _this.log.debug('Got Query', queryName);
        _this._verifyContextIsInitialized(queryName);
        if (!_this._queryHandlers[queryName]) {
          err = "Given query " + queryName + " not registered on context";
          _this.log.error(err);
          err = new Error(err);
          return reject(err);
        }
        executeQuery = _this._queryHandlers[queryName].apply(_this._di, [params]);
        return Promise.all([executeQuery]).then(function(_arg) {
          var result;
          result = _arg[0];
          _this.log.debug("Completed Query " + queryName + " with Result " + result);
          return resolve(result);
        })["catch"](function(err) {
          return reject(err);
        });
      };
    })(this));
  };

  Context.prototype.destroy = function() {
    return this._eventBus.destroy().then((function(_this) {
      return function() {
        _this.command = void 0;
        return _this.emitDomainEvent = void 0;
      };
    })(this));
  };

  Context.prototype._verifyContextIsInitialized = function(methodName) {
    var errorMessage;
    if (!this._initialized) {
      errorMessage = "Context " + this.name + " not initialized yet, cannot execute " + methodName;
      this.log.error(errorMessage);
      throw new Error(errorMessage);
    }
  };

  return Context;

})();

module.exports = Context;
