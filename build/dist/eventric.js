(function() {

  'use strict';

  var globals = typeof window === 'undefined' ? global : window;
  if (typeof globals.require === 'function') return;

  var _definedModules = {};
  var _aliases = {};

  var Module = {
    _load: function(request, parent) {
      var name = Module._resolveFilename(request, parent);
      var definition = _definedModules[name];
      if (!definition) throw new Error('Cannot find module "' + name + '" from '+ '"' + parent + '"');

      if (Module._cache[name]) return Module._cache[name].exports;

      var localRequire = createLocalRequire(name);
      var module = {id: name, exports: {}};
      Module._cache[name] = module;
      definition.call(module.exports, module.exports, localRequire, module);
      return module.exports;
    },
    _cache: {},
    // TODO: Implement this to behave more like the Node environment
    _resolveFilename: function(request, parent) {
      var path = expand(dirname(parent), request);
      if (_definedModules.hasOwnProperty(path)) return path;
      path = expand(path, './index');
      if (_definedModules.hasOwnProperty(path)) return path;
      return request;
    }
  };

  var require = function(name, loaderPath) {
    return Module._load(name, loaderPath);
  };


  var expand = (function() {
    var reg = /^\.\.?(\/|$)/;
    return function(root, name) {
      var results = [], parts, part;
      parts = (reg.test(name) ? root + '/' + name : name).split('/');
      for (var i = 0, length = parts.length; i < length; i++) {
        part = parts[i];
        if (part === '..') {
          results.pop();
        } else if (part !== '.' && part !== '') {
          results.push(part);
        }
      }
      return results.join('/');
    };
  })();

  var createLocalRequire = function(parent) {
    return function(name) {
      return globals.require(name, parent);
    };
  };

  var dirname = function(path) {
    if (!path) return '';
    return path.split('/').slice(0, -1).join('/');
  };

  require.register = require.define = function(bundle, fn) {
    if (typeof bundle === 'object') {
      for (var key in bundle) {
        if (bundle.hasOwnProperty(key)) {
          _definedModules[key] = bundle[key];
        }
      }
    } else {
      _definedModules[bundle] = fn;
    }
  };

  require.list = function() {
    var result = [];
    for (var item in _definedModules) {
      if (_definedModules.hasOwnProperty(item)) {
        result.push(item);
      }
    }
    return result;
  };

  globals.require = require;

  require.define('module', function(exports, require, module) {
    module.exports = Module;
  });

})();
require.register("eventric/eventric", function(exports, require, module){
  var Eventric,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __slice = [].slice;

Eventric = (function() {
  function Eventric() {
    this._handleRemoteRPCRequest = __bind(this._handleRemoteRPCRequest, this);
    this.PubSub = require('./pub_sub');
    this.EventBus = require('./event_bus');
    this.Remote = require('./remote');
    this.Context = require('./context');
    this.DomainEvent = require('./domain_event');
    this.Aggregate = require('./aggregate');
    this.Repository = require('./repository');
    this.Projection = require('./projection');
    this.Logger = require('./logger');
    this.RemoteInMemory = require('./remote/inmemory');
    this.StoreInMemory = require('./store/inmemory');
    this.GlobalContext = require('./global_context');
    this.log = this.Logger;
    this._contexts = {};
    this._params = {};
    this._domainEventHandlers = {};
    this._domainEventHandlersAll = [];
    this._storeClasses = {};
    this._remoteEndpoints = [];
    this._globalProjectionClasses = [];
    this._globalContext = new this.GlobalContext(this);
    this._projectionService = new this.Projection(this, this._globalContext);
    this.addRemoteEndpoint('inmemory', this.RemoteInMemory.endpoint);
    this.addStore('inmemory', this.StoreInMemory);
    this.set('default domain events store', 'inmemory');
  }

  Eventric.prototype.set = function(key, value) {
    return this._params[key] = value;
  };

  Eventric.prototype.get = function(key) {
    if (!key) {
      return this._params;
    } else {
      return this._params[key];
    }
  };

  Eventric.prototype.addStore = function(storeName, StoreClass, storeOptions) {
    if (storeOptions == null) {
      storeOptions = {};
    }
    return this._storeClasses[storeName] = {
      Class: StoreClass,
      options: storeOptions
    };
  };

  Eventric.prototype.getStores = function() {
    return this._storeClasses;
  };

  Eventric.prototype.context = function(name) {
    var context, error;
    if (!name) {
      error = 'Contexts must have a name';
      this.log.error(error);
      throw new Error(error);
    }
    context = new this.Context(name, this);
    this._delegateAllDomainEventsToGlobalHandlers(context);
    this._delegateAllDomainEventsToRemoteEndpoints(context);
    this._contexts[name] = context;
    return context;
  };

  Eventric.prototype.initializeGlobalProjections = function() {
    return Promise.all(this._globalProjectionClasses.map((function(_this) {
      return function(GlobalProjectionClass) {
        return _this._projectionService.initializeInstance('', new GlobalProjectionClass, {});
      };
    })(this)));
  };

  Eventric.prototype.addGlobalProjection = function(ProjectionClass) {
    return this._globalProjectionClasses.push(ProjectionClass);
  };

  Eventric.prototype.getRegisteredContextNames = function() {
    return Object.keys(this._contexts);
  };

  Eventric.prototype.getContext = function(name) {
    return this._contexts[name];
  };

  Eventric.prototype.remote = function(contextName) {
    var err;
    if (!contextName) {
      err = 'Missing context name';
      this.log.error(err);
      throw new Error(err);
    }
    return new this.Remote(contextName, this);
  };

  Eventric.prototype.addRemoteEndpoint = function(remoteName, remoteEndpoint) {
    this._remoteEndpoints.push(remoteEndpoint);
    return remoteEndpoint.setRPCHandler(this._handleRemoteRPCRequest);
  };

  Eventric.prototype._handleRemoteRPCRequest = function(request, callback) {
    var context, error;
    context = this.getContext(request.contextName);
    if (!context) {
      error = "Tried to handle Remote RPC with not registered context " + request.contextName;
      this.log.error(error);
      return callback(error, null);
    }
    if (this.Remote.ALLOWED_RPC_OPERATIONS.indexOf(request.functionName) === -1) {
      error = "RPC operation '" + request.functionName + "' not allowed";
      this.log.error(error);
      return callback(error, null);
    }
    if (!(request.functionName in context)) {
      error = "Remote RPC function " + request.functionName + " not found on Context " + request.contextName;
      this.log.error(error);
      return callback(error, null);
    }
    return context[request.functionName].apply(context, request.args).then(function(result) {
      return callback(null, result);
    })["catch"](function(error) {
      return callback(error);
    });
  };

  Eventric.prototype._delegateAllDomainEventsToGlobalHandlers = function(context) {
    return context.subscribeToAllDomainEvents((function(_this) {
      return function(domainEvent) {
        var eventHandler, eventHandlers, _i, _len, _results;
        eventHandlers = _this.getDomainEventHandlers(context.name, domainEvent.name);
        _results = [];
        for (_i = 0, _len = eventHandlers.length; _i < _len; _i++) {
          eventHandler = eventHandlers[_i];
          _results.push(eventHandler(domainEvent));
        }
        return _results;
      };
    })(this));
  };

  Eventric.prototype._delegateAllDomainEventsToRemoteEndpoints = function(context) {
    return context.subscribeToAllDomainEvents((function(_this) {
      return function(domainEvent) {
        return _this._remoteEndpoints.forEach(function(remoteEndpoint) {
          remoteEndpoint.publish(context.name, domainEvent.name, domainEvent);
          if (domainEvent.aggregate) {
            return remoteEndpoint.publish(context.name, domainEvent.name, domainEvent.aggregate.id, domainEvent);
          }
        });
      };
    })(this));
  };

  Eventric.prototype.subscribeToDomainEvent = function() {
    var contextName, eventHandler, eventName, _arg, _base, _base1, _i;
    _arg = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), eventHandler = arguments[_i++];
    contextName = _arg[0], eventName = _arg[1];
    if (contextName == null) {
      contextName = 'all';
    }
    if (eventName == null) {
      eventName = 'all';
    }
    if (contextName === 'all' && eventName === 'all') {
      return this._domainEventHandlersAll.push(eventHandler);
    } else {
      if ((_base = this._domainEventHandlers)[contextName] == null) {
        _base[contextName] = {};
      }
      if ((_base1 = this._domainEventHandlers[contextName])[eventName] == null) {
        _base1[eventName] = [];
      }
      return this._domainEventHandlers[contextName][eventName].push(eventHandler);
    }
  };

  Eventric.prototype.getDomainEventHandlers = function(contextName, domainEventName) {
    var _ref, _ref1, _ref2, _ref3, _ref4;
    return [].concat((_ref = (_ref1 = this._domainEventHandlers[contextName]) != null ? _ref1[domainEventName] : void 0) != null ? _ref : [], (_ref2 = (_ref3 = this._domainEventHandlers[contextName]) != null ? _ref3.all : void 0) != null ? _ref2 : [], (_ref4 = this._domainEventHandlersAll) != null ? _ref4 : []);
  };

  Eventric.prototype.generateUid = function(separator) {
    var S4, delim;
    S4 = function() {
      return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    };
    delim = separator || "-";
    return S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4();
  };

  Eventric.prototype.defaults = function(options, optionDefaults) {
    var allKeys, key, _i, _len;
    allKeys = [].concat(Object.keys(options), Object.keys(optionDefaults));
    for (_i = 0, _len = allKeys.length; _i < _len; _i++) {
      key = allKeys[_i];
      if (!options[key] && optionDefaults[key]) {
        options[key] = optionDefaults[key];
      }
    }
    return options;
  };

  Eventric.prototype.mixin = function(destination, source) {
    var prop, _results;
    _results = [];
    for (prop in source) {
      _results.push(destination[prop] = source[prop]);
    }
    return _results;
  };

  return Eventric;

})();

module.exports = Eventric;

  
});

require.register("eventric/index", function(exports, require, module){
  module.exports = new (require('./eventric'));

  
});

require.register("eventric/aggregate/aggregate", function(exports, require, module){
  var Aggregate,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Aggregate = (function() {
  function Aggregate(_at__context, _at__eventric, _at__name, Root) {
    this._context = _at__context;
    this._eventric = _at__eventric;
    this._name = _at__name;
    this.getDomainEvents = __bind(this.getDomainEvents, this);
    this.emitDomainEvent = __bind(this.emitDomainEvent, this);
    this._domainEvents = [];
    if (!Root) {
      this.root = {};
    } else {
      this.root = new Root;
    }
    this.root.$emitDomainEvent = this.emitDomainEvent;
  }

  Aggregate.prototype.emitDomainEvent = function(domainEventName, domainEventPayload) {
    var DomainEventClass, aggregate, domainEvent, err;
    DomainEventClass = this._context.getDomainEvent(domainEventName);
    if (!DomainEventClass) {
      err = "Tried to emitDomainEvent '" + domainEventName + "' which is not defined";
      this._eventric.log.error(err);
      throw new Error(err);
    }
    aggregate = {
      id: this.id,
      name: this._name
    };
    domainEvent = this._context.createDomainEvent(domainEventName, DomainEventClass, domainEventPayload, aggregate);
    this._domainEvents.push(domainEvent);
    this._handleDomainEvent(domainEventName, domainEvent);
    return this._eventric.log.debug("Created and Handled DomainEvent in Aggregate", domainEvent);
  };

  Aggregate.prototype._handleDomainEvent = function(domainEventName, domainEvent) {
    if (this.root["handle" + domainEventName]) {
      return this.root["handle" + domainEventName](domainEvent, function() {});
    } else {
      return this._eventric.log.debug("Tried to handle the DomainEvent '" + domainEventName + "' without a matching handle method");
    }
  };

  Aggregate.prototype.getDomainEvents = function() {
    return this._domainEvents;
  };

  Aggregate.prototype.applyDomainEvents = function(domainEvents) {
    var domainEvent, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = domainEvents.length; _i < _len; _i++) {
      domainEvent = domainEvents[_i];
      _results.push(this._applyDomainEvent(domainEvent));
    }
    return _results;
  };

  Aggregate.prototype._applyDomainEvent = function(domainEvent) {
    return this._handleDomainEvent(domainEvent.name, domainEvent);
  };

  return Aggregate;

})();

module.exports = Aggregate;

  
});

require.register("eventric/aggregate/index", function(exports, require, module){
  module.exports = require('./aggregate');

  
});

require.register("eventric/context/context", function(exports, require, module){
  var Context,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __slice = [].slice;

Context = (function() {
  function Context(_at_name, _at__eventric) {
    this.name = _at_name;
    this._eventric = _at__eventric;
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

  
});

require.register("eventric/context/index", function(exports, require, module){
  module.exports = require('./context');

  
});

require.register("eventric/domain_event/domain_event", function(exports, require, module){
  var DomainEvent;

DomainEvent = (function() {
  function DomainEvent(params) {
    this.id = params.id;
    this.name = params.name;
    this.payload = params.payload;
    this.aggregate = params.aggregate;
    this.context = params.context;
    this.timestamp = new Date().getTime();
  }

  return DomainEvent;

})();

module.exports = DomainEvent;

  
});

require.register("eventric/domain_event/index", function(exports, require, module){
  module.exports = require('./domain_event');

  
});

require.register("eventric/event_bus/event_bus", function(exports, require, module){
  var EventBus;

EventBus = (function() {
  function EventBus(_at__eventric) {
    this._eventric = _at__eventric;
    this._pubSub = new this._eventric.PubSub();
    this._publishQueue = new Promise(function(resolve) {
      return resolve();
    });
  }

  EventBus.prototype.subscribeToDomainEvent = function(eventName, handlerFn) {
    return this._pubSub.subscribe(eventName, handlerFn);
  };

  EventBus.prototype.subscribeToDomainEventWithAggregateId = function(eventName, aggregateId, handlerFn) {
    return this.subscribeToDomainEvent(eventName + "/" + aggregateId, handlerFn);
  };

  EventBus.prototype.subscribeToAllDomainEvents = function(handlerFn) {
    return this.subscribeToDomainEvent('DomainEvent', handlerFn);
  };

  EventBus.prototype.publishDomainEvent = function(domainEvent) {
    return this._enqueuePublishing((function(_this) {
      return function() {
        return _this._publishDomainEvent(domainEvent);
      };
    })(this));
  };

  EventBus.prototype._enqueuePublishing = function(publishOperation) {
    return this._publishQueue = this._publishQueue.then(publishOperation);
  };

  EventBus.prototype._publishDomainEvent = function(domainEvent) {
    var eventName, publishPasses, _ref;
    publishPasses = [this._pubSub.publish('DomainEvent', domainEvent), this._pubSub.publish(domainEvent.name, domainEvent)];
    if ((_ref = domainEvent.aggregate) != null ? _ref.id : void 0) {
      eventName = domainEvent.name + "/" + domainEvent.aggregate.id;
      publishPasses.push(this._pubSub.publish(eventName, domainEvent));
    }
    return Promise.all(publishPasses);
  };

  EventBus.prototype.destroy = function() {
    return this._pubSub.destroy().then((function(_this) {
      return function() {
        return _this.publishDomainEvent = void 0;
      };
    })(this));
  };

  return EventBus;

})();

module.exports = EventBus;

  
});

require.register("eventric/event_bus/index", function(exports, require, module){
  module.exports = require('./event_bus');

  
});

require.register("eventric/global_context/global_context", function(exports, require, module){
  var GlobalContext,
  __slice = [].slice;

GlobalContext = (function() {
  function GlobalContext(_at__eventric) {
    this._eventric = _at__eventric;
    this.name = 'Global';
  }

  GlobalContext.prototype.findDomainEventsByName = function() {
    var findArguments, findDomainEventsByName;
    findArguments = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    findDomainEventsByName = this._getAllContexts().map(function(context) {
      return context.findDomainEventsByName.apply(context, findArguments);
    });
    return Promise.all(findDomainEventsByName).then((function(_this) {
      return function(domainEventsByContext) {
        var domainEvents;
        domainEvents = _this._combineDomainEventsByContext(domainEventsByContext);
        return _this._sortDomainEventsByTimestamp(domainEvents);
      };
    })(this));
  };

  GlobalContext.prototype.subscribeToDomainEvent = function(eventName, domainEventHandler) {
    var subscribeToDomainEvents;
    subscribeToDomainEvents = this._getAllContexts().map(function(context) {
      return context.subscribeToDomainEvent(eventName, domainEventHandler);
    });
    return Promise.all(subscribeToDomainEvents);
  };

  GlobalContext.prototype._getAllContexts = function() {
    var contextNames;
    contextNames = this._eventric.getRegisteredContextNames();
    return contextNames.map((function(_this) {
      return function(contextName) {
        return _this._eventric.remote(contextName);
      };
    })(this));
  };

  GlobalContext.prototype._combineDomainEventsByContext = function(domainEventsByContext) {
    return domainEventsByContext.reduce(function(allDomainEvents, contextDomainEvents) {
      return allDomainEvents.concat(contextDomainEvents);
    }, []);
  };

  GlobalContext.prototype._sortDomainEventsByTimestamp = function(domainEvents) {
    return domainEvents.sort(function(firstEvent, secondEvent) {
      return firstEvent.timestamp - secondEvent.timestamp;
    });
  };

  return GlobalContext;

})();

module.exports = GlobalContext;

  
});

require.register("eventric/global_context/index", function(exports, require, module){
  module.exports = require('./global_context');

  
});

require.register("eventric/logger/index", function(exports, require, module){
  module.exports = require('./logger');

  
});

require.register("eventric/logger/logger", function(exports, require, module){
  module.exports = {
  _logLevel: 1,
  setLogLevel: function(logLevel) {
    return this._logLevel = (function() {
      switch (logLevel) {
        case 'debug':
          return 0;
        case 'warn':
          return 1;
        case 'info':
          return 2;
        case 'error':
          return 3;
      }
    })();
  },
  debug: function() {
    if (this._logLevel > 0) {
      return;
    }
    return console.log.apply(console, arguments);
  },
  warn: function() {
    if (this._logLevel > 1) {
      return;
    }
    return console.log.apply(console, arguments);
  },
  info: function() {
    if (this._logLevel > 2) {
      return;
    }
    return console.log.apply(console, arguments);
  },
  error: function() {
    if (this._logLevel > 3) {
      return;
    }
    return console.log.apply(console, arguments);
  }
};

  
});

require.register("eventric/projection/index", function(exports, require, module){
  module.exports = require('./projection');

  
});

require.register("eventric/projection/projection", function(exports, require, module){
  var Projection,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Projection = (function() {
  function Projection(_at__eventric, _at__context) {
    this._eventric = _at__eventric;
    this._context = _at__context;
    this._applyDomainEventToProjection = __bind(this._applyDomainEventToProjection, this);
    this.log = this._eventric.log;
    this._handlerFunctions = {};
    this._projectionInstances = {};
    this._domainEventsApplied = {};
  }

  Projection.prototype.initializeInstance = function(projectionName, Projection, params) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var aggregateId, diFn, diName, eventNames, projection, projectionId, _ref;
        if (typeof Projection === 'function') {
          projection = new Projection;
        } else {
          projection = Projection;
        }
        if (_this._context._di) {
          _ref = _this._context._di;
          for (diName in _ref) {
            diFn = _ref[diName];
            projection[diName] = diFn;
          }
        }
        projectionId = _this._eventric.generateUid();
        aggregateId = null;
        projection.$subscribeHandlersWithAggregateId = function(_aggregateId) {
          return aggregateId = _aggregateId;
        };
        _this.log.debug("[" + _this._context.name + "] Clearing ProjectionStores " + projection.stores + " of " + projectionName);
        eventNames = null;
        return _this._clearProjectionStores(projection.stores, projectionName).then(function() {
          _this.log.debug("[" + _this._context.name + "] Finished clearing ProjectionStores of " + projectionName);
          return _this._injectStoresIntoProjection(projectionName, projection);
        }).then(function() {
          return _this._callInitializeOnProjection(projectionName, projection, params);
        }).then(function() {
          _this.log.debug("[" + _this._context.name + "] Replaying DomainEvents against Projection " + projectionName);
          return _this._parseEventNamesFromProjection(projection);
        }).then(function(_eventNames) {
          eventNames = _eventNames;
          return _this._applyDomainEventsFromStoreToProjection(projectionId, projection, eventNames, aggregateId);
        }).then(function() {
          _this.log.debug("[" + _this._context.name + "] Finished Replaying DomainEvents against Projection " + projectionName);
          return _this._subscribeProjectionToDomainEvents(projectionId, projectionName, projection, eventNames, aggregateId);
        }).then(function() {
          var event;
          _this._projectionInstances[projectionId] = projection;
          event = {
            id: projectionId,
            projection: projection
          };
          return resolve(projectionId);
        })["catch"](function(err) {
          return reject(err);
        });
      };
    })(this));
  };

  Projection.prototype._callInitializeOnProjection = function(projectionName, projection, params) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        if (!projection.initialize) {
          _this.log.debug("[" + _this._context.name + "] No initialize function on Projection " + projectionName + " given, skipping");
          return resolve(projection);
        }
        _this.log.debug("[" + _this._context.name + "] Calling initialize on Projection " + projectionName);
        return projection.initialize(params, function() {
          _this.log.debug("[" + _this._context.name + "] Finished initialize call on Projection " + projectionName);
          return resolve(projection);
        });
      };
    })(this));
  };

  Projection.prototype._injectStoresIntoProjection = function(projectionName, projection) {
    var promise, _ref;
    promise = new Promise(function(resolve) {
      return resolve();
    });
    if (!projection.stores) {
      return promise;
    }
    if (projection["$store"] == null) {
      projection["$store"] = {};
    }
    if ((_ref = projection.stores) != null) {
      _ref.forEach((function(_this) {
        return function(projectionStoreName) {
          _this.log.debug("[" + _this._context.name + "] Injecting ProjectionStore " + projectionStoreName + " into Projection " + projectionName);
          return promise = promise.then(function() {
            return _this._context.getProjectionStore(projectionStoreName, projectionName);
          }).then(function(projectionStore) {
            if (projectionStore) {
              projection["$store"][projectionStoreName] = projectionStore;
              return _this.log.debug("[" + _this._context.name + "] Finished Injecting ProjectionStore " + projectionStoreName + " into Projection " + projectionName);
            }
          });
        };
      })(this));
    }
    return promise;
  };

  Projection.prototype._clearProjectionStores = function(projectionStores, projectionName) {
    var promise;
    promise = new Promise(function(resolve) {
      return resolve();
    });
    if (!projectionStores) {
      return promise;
    }
    projectionStores.forEach((function(_this) {
      return function(projectionStoreName) {
        _this.log.debug("[" + _this._context.name + "] Clearing ProjectionStore " + projectionStoreName + " for " + projectionName);
        return promise = promise.then(function() {
          return _this._context.clearProjectionStore(projectionStoreName, projectionName);
        }).then(function() {
          return _this.log.debug("[" + _this._context.name + "] Finished clearing ProjectionStore " + projectionStoreName + " for " + projectionName);
        });
      };
    })(this));
    return promise;
  };

  Projection.prototype._parseEventNamesFromProjection = function(projection) {
    return new Promise(function(resolve, reject) {
      var eventName, eventNames, key, value;
      eventNames = [];
      for (key in projection) {
        value = projection[key];
        if ((key.indexOf('handle')) === 0 && (typeof value === 'function')) {
          eventName = key.replace(/^handle/, '');
          eventNames.push(eventName);
        }
      }
      return resolve(eventNames);
    });
  };

  Projection.prototype._applyDomainEventsFromStoreToProjection = function(projectionId, projection, eventNames, aggregateId) {
    var findEvents;
    this._domainEventsApplied[projectionId] = {};
    if (aggregateId) {
      findEvents = this._context.findDomainEventsByNameAndAggregateId(eventNames, aggregateId);
    } else {
      findEvents = this._context.findDomainEventsByName(eventNames);
    }
    return findEvents.then((function(_this) {
      return function(domainEvents) {
        var applyDomainEventsToProjection;
        if (!domainEvents || domainEvents.length === 0) {
          return;
        }
        applyDomainEventsToProjection = new Promise(function(resolve) {
          return resolve();
        });
        domainEvents.forEach(function(domainEvent) {
          return applyDomainEventsToProjection = applyDomainEventsToProjection.then(function() {
            return _this._applyDomainEventToProjection(domainEvent, projection);
          }).then(function() {
            return _this._domainEventsApplied[projectionId][domainEvent.id] = true;
          });
        });
        return applyDomainEventsToProjection;
      };
    })(this));
  };

  Projection.prototype._subscribeProjectionToDomainEvents = function(projectionId, projectionName, projection, eventNames, aggregateId) {
    var domainEventHandler, promise;
    domainEventHandler = (function(_this) {
      return function(domainEvent, done) {
        if (done == null) {
          done = function() {};
        }
        if (_this._domainEventsApplied[projectionId][domainEvent.id]) {
          return done();
        }
        return _this._applyDomainEventToProjection(domainEvent, projection).then(function() {
          var event;
          _this._domainEventsApplied[projectionId][domainEvent.id] = true;
          event = {
            id: projectionId,
            projection: projection,
            domainEvent: domainEvent
          };
          return done();
        })["catch"](function(err) {
          return done(err);
        });
      };
    })(this);
    promise = new Promise(function(resolve) {
      return resolve();
    });
    eventNames.forEach((function(_this) {
      return function(eventName) {
        return promise = promise.then(function() {
          if (aggregateId) {
            return _this._context.subscribeToDomainEventWithAggregateId(eventName, aggregateId, domainEventHandler);
          } else {
            return _this._context.subscribeToDomainEvent(eventName, domainEventHandler);
          }
        }).then(function(subscriberId) {
          var _base;
          if ((_base = _this._handlerFunctions)[projectionId] == null) {
            _base[projectionId] = [];
          }
          return _this._handlerFunctions[projectionId].push(subscriberId);
        });
      };
    })(this));
    return promise;
  };

  Projection.prototype._applyDomainEventToProjection = function(domainEvent, projection) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var handleDomainEvent;
        if (!projection["handle" + domainEvent.name]) {
          _this.log.debug("Tried to apply DomainEvent '" + domainEvent.name + "' to Projection without a matching handle method");
          resolve();
          return;
        }
        handleDomainEvent = projection["handle" + domainEvent.name](domainEvent);
        return Promise.all([handleDomainEvent]).then(function(_arg) {
          var result;
          result = _arg[0];
          return resolve(result);
        });
      };
    })(this));
  };

  Projection.prototype.getInstance = function(projectionId) {
    return this._projectionInstances[projectionId];
  };

  Projection.prototype.destroyInstance = function(projectionId) {
    var subscriberId, unsubscribePromises, _i, _len, _ref;
    if (!this._handlerFunctions[projectionId]) {
      return this.log.error('Missing attribute projectionId');
    }
    unsubscribePromises = [];
    _ref = this._handlerFunctions[projectionId];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      subscriberId = _ref[_i];
      unsubscribePromises.push(this._context.unsubscribeFromDomainEvent(subscriberId));
    }
    delete this._handlerFunctions[projectionId];
    delete this._projectionInstances[projectionId];
    return Promise.all(unsubscribePromises);
  };

  return Projection;

})();

module.exports = Projection;

  
});

require.register("eventric/pub_sub/index", function(exports, require, module){
  module.exports = require('./pub_sub');

  
});

require.register("eventric/pub_sub/pub_sub", function(exports, require, module){
  var PubSub;

PubSub = (function() {
  function PubSub() {
    this._subscribers = [];
    this._subscriberId = 0;
    this._pendingPublishOperations = [];
  }

  PubSub.prototype.subscribe = function(eventName, subscriberFunction) {
    return new Promise((function(_this) {
      return function(resolve) {
        var subscriber;
        subscriber = {
          eventName: eventName,
          subscriberFunction: subscriberFunction,
          subscriberId: _this._getNextSubscriberId()
        };
        _this._subscribers.push(subscriber);
        return resolve(subscriber.subscriberId);
      };
    })(this));
  };

  PubSub.prototype.publish = function(eventName, payload) {
    var executeSubscriberFunctions, subscribers;
    subscribers = this._getRelevantSubscribers(eventName);
    executeSubscriberFunctions = Promise.all(subscribers.map(function(subscriber) {
      return subscriber.subscriberFunction(payload);
    }));
    this._addPendingPublishOperation(executeSubscriberFunctions);
    return executeSubscriberFunctions;
  };

  PubSub.prototype._getRelevantSubscribers = function(eventName) {
    if (eventName) {
      return this._subscribers.filter(function(subscriber) {
        return subscriber.eventName === eventName;
      });
    } else {
      return this._subscribers;
    }
  };

  PubSub.prototype._addPendingPublishOperation = function(publishOperation) {
    this._pendingPublishOperations.push(publishOperation);
    return publishOperation.then((function(_this) {
      return function() {
        return _this._pendingPublishOperations.splice(_this._pendingPublishOperations.indexOf(publishOperation), 1);
      };
    })(this));
  };

  PubSub.prototype.unsubscribe = function(subscriberId) {
    return new Promise((function(_this) {
      return function(resolve) {
        _this._subscribers = _this._subscribers.filter(function(subscriber) {
          return subscriber.subscriberId !== subscriberId;
        });
        return resolve();
      };
    })(this));
  };

  PubSub.prototype._getNextSubscriberId = function() {
    return this._subscriberId++;
  };

  PubSub.prototype.destroy = function() {
    return Promise.all(this._pendingPublishOperations).then((function(_this) {
      return function() {
        return _this.publish = void 0;
      };
    })(this));
  };

  return PubSub;

})();

module.exports = PubSub;

  
});

require.register("eventric/remote/index", function(exports, require, module){
  module.exports = require('./remote');

  
});

require.register("eventric/remote/remote", function(exports, require, module){
  var Remote;

Remote = (function() {
  Remote.ALLOWED_RPC_OPERATIONS = ['command', 'query', 'findDomainEventsByName', 'findDomainEventsByNameAndAggregateId'];

  function Remote(_at__contextName, _at__eventric) {
    this._contextName = _at__contextName;
    this._eventric = _at__eventric;
    this.name = this._contextName;
    this.InMemoryRemote = require('./inmemory');
    this._params = {};
    this._clients = {};
    this._projectionClasses = {};
    this._projectionInstances = {};
    this._handlerFunctions = {};
    this.projectionService = new this._eventric.Projection(this._eventric, this);
    this.addClient('inmemory', this.InMemoryRemote.client);
    this.set('default client', 'inmemory');
    this._exposeRpcOperationsAsMemberFunctions();
  }

  Remote.prototype._exposeRpcOperationsAsMemberFunctions = function() {
    return Remote.ALLOWED_RPC_OPERATIONS.forEach((function(_this) {
      return function(rpcOperation) {
        return _this[rpcOperation] = function() {
          return _this._rpc(rpcOperation, arguments);
        };
      };
    })(this));
  };

  Remote.prototype.set = function(key, value) {
    this._params[key] = value;
    return this;
  };

  Remote.prototype.get = function(key) {
    return this._params[key];
  };

  Remote.prototype.subscribeToAllDomainEvents = function(handlerFn) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.subscribe(this._contextName, handlerFn);
  };

  Remote.prototype.subscribeToDomainEvent = function(domainEventName, handlerFn) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.subscribe(this._contextName, domainEventName, handlerFn);
  };

  Remote.prototype.subscribeToDomainEventWithAggregateId = function(domainEventName, aggregateId, handlerFn) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.subscribe(this._contextName, domainEventName, aggregateId, handlerFn);
  };

  Remote.prototype.unsubscribeFromDomainEvent = function(subscriberId) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.unsubscribe(subscriberId);
  };

  Remote.prototype._rpc = function(functionName, args) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.rpc({
      contextName: this._contextName,
      functionName: functionName,
      args: Array.prototype.slice.call(args)
    });
  };

  Remote.prototype.addClient = function(clientName, client) {
    this._clients[clientName] = client;
    return this;
  };

  Remote.prototype.getClient = function(clientName) {
    return this._clients[clientName];
  };

  Remote.prototype.addProjection = function(projectionName, projectionClass) {
    this._projectionClasses[projectionName] = projectionClass;
    return this;
  };

  Remote.prototype.initializeProjection = function(projectionObject, params) {
    return this.projectionService.initializeInstance('', projectionObject, params);
  };

  Remote.prototype.initializeProjectionInstance = function(projectionName, params) {
    var err;
    if (!this._projectionClasses[projectionName]) {
      err = "Given projection " + projectionName + " not registered on remote";
      this._eventric.log.error(err);
      err = new Error(err);
      return err;
    }
    return this.projectionService.initializeInstance(projectionName, this._projectionClasses[projectionName], params);
  };

  Remote.prototype.getProjectionInstance = function(projectionId) {
    return this.projectionService.getInstance(projectionId);
  };

  Remote.prototype.destroyProjectionInstance = function(projectionId) {
    return this.projectionService.destroyInstance(projectionId, this);
  };

  return Remote;

})();

module.exports = Remote;

  
});

require.register("eventric/repository/index", function(exports, require, module){
  module.exports = require('./repository');

  
});

require.register("eventric/repository/repository", function(exports, require, module){
  var Repository,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Repository = (function() {
  function Repository(params, _at__eventric) {
    this._eventric = _at__eventric;
    this.save = __bind(this.save, this);
    this.create = __bind(this.create, this);
    this.findById = __bind(this.findById, this);
    this._aggregateName = params.aggregateName;
    this._AggregateRoot = params.AggregateRoot;
    this._context = params.context;
    this._eventric = params.eventric;
    this._command = {};
    this._aggregateInstances = {};
    this._store = this._context.getDomainEventsStore();
  }

  Repository.prototype.findById = function(aggregateId, callback) {
    if (callback == null) {
      callback = function() {};
    }
    return new Promise((function(_this) {
      return function(resolve, reject) {
        return _this._findDomainEventsForAggregate(aggregateId, function(err, domainEvents) {
          var aggregate, commandId, _base, _ref;
          if (err) {
            callback(err, null);
            reject(err);
            return;
          }
          if (!domainEvents.length) {
            err = "No domainEvents for " + _this._aggregateName + " Aggregate with " + aggregateId + " available";
            _this._eventric.log.error(err);
            callback(err, null);
            reject(err);
            return;
          }
          aggregate = new _this._eventric.Aggregate(_this._context, _this._eventric, _this._aggregateName, _this._AggregateRoot);
          aggregate.applyDomainEvents(domainEvents);
          aggregate.id = aggregateId;
          aggregate.root.$id = aggregateId;
          aggregate.root.$save = function() {
            return _this.save(aggregate.id);
          };
          commandId = (_ref = _this._command.id) != null ? _ref : 'nocommand';
          if ((_base = _this._aggregateInstances)[commandId] == null) {
            _base[commandId] = {};
          }
          _this._aggregateInstances[commandId][aggregateId] = aggregate;
          callback(null, aggregate.root);
          return resolve(aggregate.root);
        });
      };
    })(this));
  };

  Repository.prototype._findDomainEventsForAggregate = function(aggregateId, callback) {
    return this._store.findDomainEventsByAggregateId(aggregateId, function(err, domainEvents) {
      if (err) {
        return callback(err, null);
      }
      if (domainEvents.length === 0) {
        return callback(null, []);
      }
      return callback(null, domainEvents);
    });
  };

  Repository.prototype.create = function(params) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var aggregate, commandId, createAggregate, err, _base, _ref;
        aggregate = new _this._eventric.Aggregate(_this._context, _this._eventric, _this._aggregateName, _this._AggregateRoot);
        aggregate.id = _this._eventric.generateUid();
        if (typeof aggregate.root.create !== 'function') {
          err = "No create function on aggregate";
          _this._eventric.log.error(err);
          reject(new Error(err));
        }
        aggregate.root.$id = aggregate.id;
        aggregate.root.$save = function() {
          return _this.save(aggregate.id);
        };
        commandId = (_ref = _this._command.id) != null ? _ref : 'nocommand';
        if ((_base = _this._aggregateInstances)[commandId] == null) {
          _base[commandId] = {};
        }
        _this._aggregateInstances[commandId][aggregate.id] = aggregate;
        createAggregate = aggregate.root.create(params);
        return Promise.all([createAggregate]).then(function() {
          return resolve(aggregate.root);
        })["catch"](function(_arg) {
          var error;
          error = _arg[0];
          return reject(error);
        });
      };
    })(this));
  };

  Repository.prototype.save = function(aggregateId) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var aggregate, commandId, domainEvents, errorMessage, saveDomainEventQueue, _ref;
        commandId = (_ref = _this._command.id) != null ? _ref : 'nocommand';
        aggregate = _this._aggregateInstances[commandId][aggregateId];
        if (!aggregate) {
          errorMessage = "Tried to save unknown aggregate " + _this._aggregateName;
          _this._eventric.log.error(errorMessage);
          throw new Error(errorMessage);
        }
        domainEvents = aggregate.getDomainEvents();
        if (domainEvents.length < 1) {
          errorMessage = "Tried to save 0 DomainEvents from Aggregate " + _this._aggregateName;
          _this._eventric.log.debug(errorMessage, _this._command);
          throw new Error(errorMessage);
        }
        _this._eventric.log.debug("Going to Save and Publish " + domainEvents.length + " DomainEvents from Aggregate " + _this._aggregateName);
        saveDomainEventQueue = new Promise(function(resolve) {
          return resolve();
        });
        domainEvents.forEach(function(domainEvent) {
          return saveDomainEventQueue = saveDomainEventQueue.then(function() {
            return _this._store.saveDomainEvent(domainEvent);
          }).then(function() {
            return _this._eventric.log.debug("Saved DomainEvent", domainEvent);
          });
        });
        return saveDomainEventQueue.then(function() {
          return domainEvents.forEach(function(domainEvent) {
            _this._eventric.log.debug("Publishing DomainEvent", domainEvent);
            return _this._context.getEventBus().publishDomainEvent(domainEvent)["catch"](function(error) {
              return _this._eventric.log.error(error);
            });
          });
        }).then(function() {
          return resolve(aggregate.id);
        })["catch"](reject);
      };
    })(this));
  };

  Repository.prototype.setCommand = function(command) {
    return this._command = command;
  };

  return Repository;

})();

module.exports = Repository;

  
});

require.register("eventric/remote/inmemory/index", function(exports, require, module){
  module.exports = require('./remote_inmemory');

  
});

require.register("eventric/remote/inmemory/remote_inmemory", function(exports, require, module){
  var InMemoryRemoteClient, InMemoryRemoteEndpoint, PubSub, customRemoteBridge, getFullEventName, pubSub,
  __slice = [].slice;

PubSub = require('../../pub_sub');

customRemoteBridge = null;

pubSub = new PubSub;

InMemoryRemoteEndpoint = (function() {
  function InMemoryRemoteEndpoint() {
    customRemoteBridge = (function(_this) {
      return function(rpcRequest) {
        return new Promise(function(resolve, reject) {
          return _this._handleRPCRequest(rpcRequest, function(error, result) {
            if (error) {
              return reject(error);
            }
            return resolve(result);
          });
        });
      };
    })(this);
  }

  InMemoryRemoteEndpoint.prototype.setRPCHandler = function(_at__handleRPCRequest) {
    this._handleRPCRequest = _at__handleRPCRequest;
  };

  InMemoryRemoteEndpoint.prototype.publish = function() {
    var aggregateId, contextName, domainEventName, fullEventName, payload, _arg, _i;
    contextName = arguments[0], _arg = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), payload = arguments[_i++];
    domainEventName = _arg[0], aggregateId = _arg[1];
    fullEventName = getFullEventName(contextName, domainEventName, aggregateId);
    return pubSub.publish(fullEventName, payload);
  };

  return InMemoryRemoteEndpoint;

})();

module.exports.endpoint = new InMemoryRemoteEndpoint;

InMemoryRemoteClient = (function() {
  function InMemoryRemoteClient() {}

  InMemoryRemoteClient.prototype.rpc = function(rpcRequest) {
    if (!customRemoteBridge) {
      throw new Error('No Remote Endpoint available for in memory client');
    }
    return customRemoteBridge(rpcRequest);
  };

  InMemoryRemoteClient.prototype.subscribe = function() {
    var aggregateId, contextName, domainEventName, fullEventName, handlerFn, _arg, _i;
    contextName = arguments[0], _arg = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), handlerFn = arguments[_i++];
    domainEventName = _arg[0], aggregateId = _arg[1];
    fullEventName = getFullEventName(contextName, domainEventName, aggregateId);
    return pubSub.subscribe(fullEventName, handlerFn);
  };

  InMemoryRemoteClient.prototype.unsubscribe = function(subscriberId) {
    return pubSub.unsubscribe(subscriberId);
  };

  return InMemoryRemoteClient;

})();

module.exports.client = new InMemoryRemoteClient;

getFullEventName = function(contextName, domainEventName, aggregateId) {
  var fullEventName;
  fullEventName = contextName;
  if (domainEventName) {
    fullEventName += "/" + domainEventName;
  }
  if (aggregateId) {
    fullEventName += "/" + aggregateId;
  }
  return fullEventName;
};

  
});

require.register("eventric/store/inmemory/index", function(exports, require, module){
  module.exports = require('./store_inmemory');

  
});

require.register("eventric/store/inmemory/store_inmemory", function(exports, require, module){
  var InMemoryStore, STORE_SUPPORTS,
  __slice = [].slice;

STORE_SUPPORTS = ['domain_events', 'projections'];

InMemoryStore = (function() {
  function InMemoryStore() {}

  InMemoryStore.prototype._domainEvents = {};

  InMemoryStore.prototype._projections = {};

  InMemoryStore.prototype.initialize = function() {
    var options, _arg, _at__context;
    _at__context = arguments[0], _arg = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    this._context = _at__context;
    options = _arg[0];
    return new Promise((function(_this) {
      return function(resolve, reject) {
        _this._domainEventsCollectionName = _this._context.name + ".DomainEvents";
        _this._projectionCollectionName = _this._context.name + ".Projections";
        _this._domainEvents[_this._domainEventsCollectionName] = [];
        return resolve();
      };
    })(this));
  };

  InMemoryStore.prototype.saveDomainEvent = function(domainEvent, callback) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        _this._domainEvents[_this._domainEventsCollectionName].push(domainEvent);
        return resolve(domainEvent);
      };
    })(this));
  };

  InMemoryStore.prototype.findDomainEventsByName = function(name, callback) {
    var checkFn, events;
    if (name instanceof Array) {
      checkFn = function(eventName) {
        return (name.indexOf(eventName)) > -1;
      };
    } else {
      checkFn = function(eventName) {
        return eventName === name;
      };
    }
    events = this._domainEvents[this._domainEventsCollectionName].filter(function(event) {
      return checkFn(event.name);
    });
    return callback(null, events);
  };

  InMemoryStore.prototype.findDomainEventsByNameAndAggregateId = function(name, aggregateId, callback) {
    var checkAggregateIdFn, checkNameFn, events;
    if (name instanceof Array) {
      checkNameFn = function(eventName) {
        return (name.indexOf(eventName)) > -1;
      };
    } else {
      checkNameFn = function(eventName) {
        return eventName === name;
      };
    }
    if (aggregateId instanceof Array) {
      checkAggregateIdFn = function(eventAggregateId) {
        return (aggregateId.indexOf(eventAggregateId)) > -1;
      };
    } else {
      checkAggregateIdFn = function(eventAggregateId) {
        return eventAggregateId === aggregateId;
      };
    }
    events = this._domainEvents[this._domainEventsCollectionName].filter(function(event) {
      var _ref;
      return (checkNameFn(event.name)) && (checkAggregateIdFn((_ref = event.aggregate) != null ? _ref.id : void 0));
    });
    return callback(null, events);
  };

  InMemoryStore.prototype.findDomainEventsByAggregateId = function(aggregateId, callback) {
    var checkFn, events;
    if (aggregateId instanceof Array) {
      checkFn = function(eventAggregateId) {
        return (aggregateId.indexOf(eventAggregateId)) > -1;
      };
    } else {
      checkFn = function(eventAggregateId) {
        return eventAggregateId === aggregateId;
      };
    }
    events = this._domainEvents[this._domainEventsCollectionName].filter(function(event) {
      var _ref;
      return checkFn((_ref = event.aggregate) != null ? _ref.id : void 0);
    });
    return callback(null, events);
  };

  InMemoryStore.prototype.getProjectionStore = function(projectionName) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var _base, _base1, _name;
        if ((_base = _this._projections)[_name = _this._projectionCollectionName] == null) {
          _base[_name] = {};
        }
        if ((_base1 = _this._projections[_this._projectionCollectionName])[projectionName] == null) {
          _base1[projectionName] = {};
        }
        return resolve(_this._projections[_this._projectionCollectionName][projectionName]);
      };
    })(this));
  };

  InMemoryStore.prototype.clearProjectionStore = function(projectionName) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var _base, _base1, _name;
        if ((_base = _this._projections)[_name = _this._projectionCollectionName] == null) {
          _base[_name] = {};
        }
        if ((_base1 = _this._projections[_this._projectionCollectionName])[projectionName] == null) {
          _base1[projectionName] = {};
        }
        delete _this._projections[_this._projectionCollectionName][projectionName];
        return resolve();
      };
    })(this));
  };

  InMemoryStore.prototype.checkSupport = function(check) {
    return (STORE_SUPPORTS.indexOf(check)) > -1;
  };

  return InMemoryStore;

})();

module.exports = InMemoryStore;

  
});
