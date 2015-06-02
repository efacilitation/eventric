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
