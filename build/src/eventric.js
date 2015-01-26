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
    this.ProcessManager = require('./process_manager');
    this.Logger = require('./logger');
    this.RemoteInMemory = require('./remote/inmemory');
    this.StoreInMemory = require('./store/inmemory');
    this.log = this.Logger;
    this._contexts = {};
    this._params = {};
    this._processManagerInstances = {};
    this._processManagerService = this.ProcessManager;
    this._domainEventHandlers = {};
    this._domainEventHandlersAll = [];
    this._storeClasses = {};
    this._remoteEndpoints = [];
    this.addRemoteEndpoint('inmemory', this.RemoteInMemory.endpoint);
    this.addStore('inmemory', this.StoreInMemory);
    this.set('default domain events store', 'inmemory');
  }


  /**
  * @name set
  * @module eventric
  * @description Configure Global parameters
  *
  * @param {String} key Name of the key
  * @param {Mixed} value Value to be set
   */

  Eventric.prototype.set = function(key, value) {
    return this._params[key] = value;
  };


  /**
  * @name get
  * @module eventric
  * @description Get Global configured parameters
  *
  * @param {String} key Name of the Key
   */

  Eventric.prototype.get = function(key) {
    if (!key) {
      return this._params;
    } else {
      return this._params[key];
    }
  };


  /**
  * @name addStore
  * @module eventric
  * @description Add Global Store
  *
  * @param {string} storeName Name of the store
  * @param {Function} StoreClass Class of the store
  * @param {Object} Options to be passed to the store on initialize
   */

  Eventric.prototype.addStore = function(storeName, StoreClass, storeOptions) {
    if (storeOptions == null) {
      storeOptions = {};
    }
    return this._storeClasses[storeName] = {
      Class: StoreClass,
      options: storeOptions
    };
  };


  /**
  * @name getStores
  * @module eventric
  * @description Get all Global added Stores
   */

  Eventric.prototype.getStores = function() {
    return this._storeClasses;
  };


  /**
  * @name context
  * @module eventric
  * @description Generate a new context instance.
  *
  * @param {String} name Name of the Context
   */

  Eventric.prototype.context = function(name) {
    var context, err, pubsub;
    if (!name) {
      err = 'Contexts must have a name';
      this.log.error(err);
      throw new Error(err);
    }
    pubsub = new this.PubSub;
    context = new this.Context(name, this);
    this.mixin(context, pubsub);
    this._delegateAllDomainEventsToGlobalHandlers(context);
    this._contexts[name] = context;
    return context;
  };


  /**
  * @name getContext
  * @module eventric
  * @decription Get a Context instance
   */

  Eventric.prototype.getContext = function(name) {
    return this._contexts[name];
  };


  /**
  * @name remote
  * @module eventric
  * @description Generate a new Remote
  *
  * @param {String} name Name of the Context to remote control
   */

  Eventric.prototype.remote = function(contextName) {
    var err, pubsub, remote;
    if (!contextName) {
      err = 'Missing context name';
      this.log.error(err);
      throw new Error(err);
    }
    pubsub = new this.PubSub;
    remote = new this.Remote(contextName, this);
    this.mixin(remote, pubsub);
    return remote;
  };


  /**
  * @name addRemoteEndpoint
  * @module eventric
  * @description Add a Global RemoteEndpoint
  *
  * @param {String} remoteName Name of the Remote
  * @param {Object} remoteEndpoint Initialized RemoteEndpoint
   */

  Eventric.prototype.addRemoteEndpoint = function(remoteName, remoteEndpoint) {
    this._remoteEndpoints.push(remoteEndpoint);
    return remoteEndpoint.setRPCHandler(this._handleRemoteRPCRequest);
  };

  Eventric.prototype._handleRemoteRPCRequest = function(request) {
    var context, err;
    context = this.getContext(request.contextName);
    if (!context) {
      err = "Tried to handle Remote RPC with not registered context " + request.contextName;
      this.log.error(err);
      return callback(err, null);
    }
    if (!(request.method in context)) {
      err = "Remote RPC method " + request.method + " not found on Context " + request.contextName;
      this.log.error(err);
      return callback(err, null);
    }
    return context[request.method].apply(context, request.params);
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


  /**
  * @name subscribeToDomainEvent
  * @module eventric
  * @description Global DomainEvent Handlers
  *
  * @param {String} contextName Name of the context or 'all'
  * @param {String} eventName Name of the Event or 'all'
  * @param {Function} eventHandler Function which handles the DomainEvent
   */

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


  /**
  * @name getDomainEventHandlers
  * @module eventric
  * @description Get all Global defined DomainEventHandlers
   */

  Eventric.prototype.getDomainEventHandlers = function(contextName, domainEventName) {
    var _ref, _ref1, _ref2, _ref3, _ref4;
    return [].concat((_ref = (_ref1 = this._domainEventHandlers[contextName]) != null ? _ref1[domainEventName] : void 0) != null ? _ref : [], (_ref2 = (_ref3 = this._domainEventHandlers[contextName]) != null ? _ref3.all : void 0) != null ? _ref2 : [], (_ref4 = this._domainEventHandlersAll) != null ? _ref4 : []);
  };


  /**
  * @name generateUid
  * @module eventric
  * @description Generate a Global Unique ID
   */

  Eventric.prototype.generateUid = function(separator) {
    var S4, delim;
    S4 = function() {
      return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
    };
    delim = separator || "-";
    return S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4();
  };


  /**
  * @name addProcessManager
  * @module eventric
  * @description Add a Global Process Manager
  *
  * @param {String} processManagerName Name of the ProcessManager
  * @param {Object} processManagerObject Object containing `initializeWhen` and `class`
   */

  Eventric.prototype.addProcessManager = function(processManagerName, processManagerObj) {
    return this._processManagerService.add(processManagerName, processManagerObj, this);
  };


  /**
  * @name nextTick
  * @module eventric
  * @description Execute a function after the nextTick
  *
  * @param {Function} next Function to be executed after the nextTick
   */

  Eventric.prototype.nextTick = function(next) {
    var nextTick, _ref;
    nextTick = (_ref = typeof process !== "undefined" && process !== null ? process.nextTick : void 0) != null ? _ref : setTimeout;
    return nextTick(function() {
      return next();
    });
  };


  /**
  * @name defaults
  * @module eventric
  * @description Apply default options to a given option object
  *
  * @param {Object} options Object which will eventually contain the options
  * @param {Object} optionDefaults Object containing default options
   */

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


  /**
  * @name eachSeries
  * @module eventric
  * @description Execute every function in the given Array in series, then the given callback
  *
  * @param {Array} arr Array containing functions
  * @param {Function} iterator Function to be called
  * @param {Function} callback Callback to be called after the function series
   */

  Eventric.prototype.eachSeries = function(arr, iterator, callback) {
    var completed, iterate;
    callback = callback || function() {};
    if (!Array.isArray(arr) || !arr.length) {
      return callback();
    }
    completed = 0;
    iterate = function() {
      iterator(arr[completed], function(err) {
        if (err) {
          callback(err);
        } else {
          ++completed;
          if (completed >= arr.length) {
            callback();
          } else {
            iterate();
          }
        }
      });
    };
    return iterate();
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
