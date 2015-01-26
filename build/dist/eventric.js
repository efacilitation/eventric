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

  
});

require.register("es6-promise", function(exports, require, module){
  (function() {
var define, requireModule, require, requirejs;

(function() {
  var registry = {}, seen = {};

  define = function(name, deps, callback) {
    registry[name] = { deps: deps, callback: callback };
  };

  requirejs = require = requireModule = function(name) {
  requirejs._eak_seen = registry;

    if (seen[name]) { return seen[name]; }
    seen[name] = {};

    if (!registry[name]) {
      throw new Error("Could not find module " + name);
    }

    var mod = registry[name],
        deps = mod.deps,
        callback = mod.callback,
        reified = [],
        exports;

    for (var i=0, l=deps.length; i<l; i++) {
      if (deps[i] === 'exports') {
        reified.push(exports = {});
      } else {
        reified.push(requireModule(resolve(deps[i])));
      }
    }

    var value = callback.apply(this, reified);
    return seen[name] = exports || value;

    function resolve(child) {
      if (child.charAt(0) !== '.') { return child; }
      var parts = child.split("/");
      var parentBase = name.split("/").slice(0, -1);

      for (var i=0, l=parts.length; i<l; i++) {
        var part = parts[i];

        if (part === '..') { parentBase.pop(); }
        else if (part === '.') { continue; }
        else { parentBase.push(part); }
      }

      return parentBase.join("/");
    }
  };
})();

define("promise/all", 
  ["./utils","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    /* global toString */

    var isArray = __dependency1__.isArray;
    var isFunction = __dependency1__.isFunction;

    /**
      Returns a promise that is fulfilled when all the given promises have been
      fulfilled, or rejected if any of them become rejected. The return promise
      is fulfilled with an array that gives all the values in the order they were
      passed in the `promises` array argument.

      Example:

      ```javascript
      var promise1 = RSVP.resolve(1);
      var promise2 = RSVP.resolve(2);
      var promise3 = RSVP.resolve(3);
      var promises = [ promise1, promise2, promise3 ];

      RSVP.all(promises).then(function(array){
        // The array here would be [ 1, 2, 3 ];
      });
      ```

      If any of the `promises` given to `RSVP.all` are rejected, the first promise
      that is rejected will be given as an argument to the returned promises's
      rejection handler. For example:

      Example:

      ```javascript
      var promise1 = RSVP.resolve(1);
      var promise2 = RSVP.reject(new Error("2"));
      var promise3 = RSVP.reject(new Error("3"));
      var promises = [ promise1, promise2, promise3 ];

      RSVP.all(promises).then(function(array){
        // Code here never runs because there are rejected promises!
      }, function(error) {
        // error.message === "2"
      });
      ```

      @method all
      @for RSVP
      @param {Array} promises
      @param {String} label
      @return {Promise} promise that is fulfilled when all `promises` have been
      fulfilled, or rejected if any of them become rejected.
    */
    function all(promises) {
      /*jshint validthis:true */
      var Promise = this;

      if (!isArray(promises)) {
        throw new TypeError('You must pass an array to all.');
      }

      return new Promise(function(resolve, reject) {
        var results = [], remaining = promises.length,
        promise;

        if (remaining === 0) {
          resolve([]);
        }

        function resolver(index) {
          return function(value) {
            resolveAll(index, value);
          };
        }

        function resolveAll(index, value) {
          results[index] = value;
          if (--remaining === 0) {
            resolve(results);
          }
        }

        for (var i = 0; i < promises.length; i++) {
          promise = promises[i];

          if (promise && isFunction(promise.then)) {
            promise.then(resolver(i), reject);
          } else {
            resolveAll(i, promise);
          }
        }
      });
    }

    __exports__.all = all;
  });
define("promise/asap", 
  ["exports"],
  function(__exports__) {
    "use strict";
    var browserGlobal = (typeof window !== 'undefined') ? window : {};
    var BrowserMutationObserver = browserGlobal.MutationObserver || browserGlobal.WebKitMutationObserver;
    var local = (typeof global !== 'undefined') ? global : (this === undefined? window:this);

    // node
    function useNextTick() {
      return function() {
        process.nextTick(flush);
      };
    }

    function useMutationObserver() {
      var iterations = 0;
      var observer = new BrowserMutationObserver(flush);
      var node = document.createTextNode('');
      observer.observe(node, { characterData: true });

      return function() {
        node.data = (iterations = ++iterations % 2);
      };
    }

    function useSetTimeout() {
      return function() {
        local.setTimeout(flush, 1);
      };
    }

    var queue = [];
    function flush() {
      for (var i = 0; i < queue.length; i++) {
        var tuple = queue[i];
        var callback = tuple[0], arg = tuple[1];
        callback(arg);
      }
      queue = [];
    }

    var scheduleFlush;

    // Decide what async method to use to triggering processing of queued callbacks:
    if (typeof process !== 'undefined' && {}.toString.call(process) === '[object process]') {
      scheduleFlush = useNextTick();
    } else if (BrowserMutationObserver) {
      scheduleFlush = useMutationObserver();
    } else {
      scheduleFlush = useSetTimeout();
    }

    function asap(callback, arg) {
      var length = queue.push([callback, arg]);
      if (length === 1) {
        // If length is 1, that means that we need to schedule an async flush.
        // If additional callbacks are queued before the queue is flushed, they
        // will be processed by this flush that we are scheduling.
        scheduleFlush();
      }
    }

    __exports__.asap = asap;
  });
define("promise/config", 
  ["exports"],
  function(__exports__) {
    "use strict";
    var config = {
      instrument: false
    };

    function configure(name, value) {
      if (arguments.length === 2) {
        config[name] = value;
      } else {
        return config[name];
      }
    }

    __exports__.config = config;
    __exports__.configure = configure;
  });
define("promise/polyfill", 
  ["./promise","./utils","exports"],
  function(__dependency1__, __dependency2__, __exports__) {
    "use strict";
    /*global self*/
    var RSVPPromise = __dependency1__.Promise;
    var isFunction = __dependency2__.isFunction;

    function polyfill() {
      var local;

      if (typeof global !== 'undefined') {
        local = global;
      } else if (typeof window !== 'undefined' && window.document) {
        local = window;
      } else {
        local = self;
      }

      var es6PromiseSupport = 
        "Promise" in local &&
        // Some of these methods are missing from
        // Firefox/Chrome experimental implementations
        "resolve" in local.Promise &&
        "reject" in local.Promise &&
        "all" in local.Promise &&
        "race" in local.Promise &&
        // Older version of the spec had a resolver object
        // as the arg rather than a function
        (function() {
          var resolve;
          new local.Promise(function(r) { resolve = r; });
          return isFunction(resolve);
        }());

      if (!es6PromiseSupport) {
        local.Promise = RSVPPromise;
      }
    }

    __exports__.polyfill = polyfill;
  });
define("promise/promise", 
  ["./config","./utils","./all","./race","./resolve","./reject","./asap","exports"],
  function(__dependency1__, __dependency2__, __dependency3__, __dependency4__, __dependency5__, __dependency6__, __dependency7__, __exports__) {
    "use strict";
    var config = __dependency1__.config;
    var configure = __dependency1__.configure;
    var objectOrFunction = __dependency2__.objectOrFunction;
    var isFunction = __dependency2__.isFunction;
    var now = __dependency2__.now;
    var all = __dependency3__.all;
    var race = __dependency4__.race;
    var staticResolve = __dependency5__.resolve;
    var staticReject = __dependency6__.reject;
    var asap = __dependency7__.asap;

    var counter = 0;

    config.async = asap; // default async is asap;

    function Promise(resolver) {
      if (!isFunction(resolver)) {
        throw new TypeError('You must pass a resolver function as the first argument to the promise constructor');
      }

      if (!(this instanceof Promise)) {
        throw new TypeError("Failed to construct 'Promise': Please use the 'new' operator, this object constructor cannot be called as a function.");
      }

      this._subscribers = [];

      invokeResolver(resolver, this);
    }

    function invokeResolver(resolver, promise) {
      function resolvePromise(value) {
        resolve(promise, value);
      }

      function rejectPromise(reason) {
        reject(promise, reason);
      }

      try {
        resolver(resolvePromise, rejectPromise);
      } catch(e) {
        rejectPromise(e);
      }
    }

    function invokeCallback(settled, promise, callback, detail) {
      var hasCallback = isFunction(callback),
          value, error, succeeded, failed;

      if (hasCallback) {
        try {
          value = callback(detail);
          succeeded = true;
        } catch(e) {
          failed = true;
          error = e;
        }
      } else {
        value = detail;
        succeeded = true;
      }

      if (handleThenable(promise, value)) {
        return;
      } else if (hasCallback && succeeded) {
        resolve(promise, value);
      } else if (failed) {
        reject(promise, error);
      } else if (settled === FULFILLED) {
        resolve(promise, value);
      } else if (settled === REJECTED) {
        reject(promise, value);
      }
    }

    var PENDING   = void 0;
    var SEALED    = 0;
    var FULFILLED = 1;
    var REJECTED  = 2;

    function subscribe(parent, child, onFulfillment, onRejection) {
      var subscribers = parent._subscribers;
      var length = subscribers.length;

      subscribers[length] = child;
      subscribers[length + FULFILLED] = onFulfillment;
      subscribers[length + REJECTED]  = onRejection;
    }

    function publish(promise, settled) {
      var child, callback, subscribers = promise._subscribers, detail = promise._detail;

      for (var i = 0; i < subscribers.length; i += 3) {
        child = subscribers[i];
        callback = subscribers[i + settled];

        invokeCallback(settled, child, callback, detail);
      }

      promise._subscribers = null;
    }

    Promise.prototype = {
      constructor: Promise,

      _state: undefined,
      _detail: undefined,
      _subscribers: undefined,

      then: function(onFulfillment, onRejection) {
        var promise = this;

        var thenPromise = new this.constructor(function() {});

        if (this._state) {
          var callbacks = arguments;
          config.async(function invokePromiseCallback() {
            invokeCallback(promise._state, thenPromise, callbacks[promise._state - 1], promise._detail);
          });
        } else {
          subscribe(this, thenPromise, onFulfillment, onRejection);
        }

        return thenPromise;
      },

      'catch': function(onRejection) {
        return this.then(null, onRejection);
      }
    };

    Promise.all = all;
    Promise.race = race;
    Promise.resolve = staticResolve;
    Promise.reject = staticReject;

    function handleThenable(promise, value) {
      var then = null,
      resolved;

      try {
        if (promise === value) {
          throw new TypeError("A promises callback cannot return that same promise.");
        }

        if (objectOrFunction(value)) {
          then = value.then;

          if (isFunction(then)) {
            then.call(value, function(val) {
              if (resolved) { return true; }
              resolved = true;

              if (value !== val) {
                resolve(promise, val);
              } else {
                fulfill(promise, val);
              }
            }, function(val) {
              if (resolved) { return true; }
              resolved = true;

              reject(promise, val);
            });

            return true;
          }
        }
      } catch (error) {
        if (resolved) { return true; }
        reject(promise, error);
        return true;
      }

      return false;
    }

    function resolve(promise, value) {
      if (promise === value) {
        fulfill(promise, value);
      } else if (!handleThenable(promise, value)) {
        fulfill(promise, value);
      }
    }

    function fulfill(promise, value) {
      if (promise._state !== PENDING) { return; }
      promise._state = SEALED;
      promise._detail = value;

      config.async(publishFulfillment, promise);
    }

    function reject(promise, reason) {
      if (promise._state !== PENDING) { return; }
      promise._state = SEALED;
      promise._detail = reason;

      config.async(publishRejection, promise);
    }

    function publishFulfillment(promise) {
      publish(promise, promise._state = FULFILLED);
    }

    function publishRejection(promise) {
      publish(promise, promise._state = REJECTED);
    }

    __exports__.Promise = Promise;
  });
define("promise/race", 
  ["./utils","exports"],
  function(__dependency1__, __exports__) {
    "use strict";
    /* global toString */
    var isArray = __dependency1__.isArray;

    /**
      `RSVP.race` allows you to watch a series of promises and act as soon as the
      first promise given to the `promises` argument fulfills or rejects.

      Example:

      ```javascript
      var promise1 = new RSVP.Promise(function(resolve, reject){
        setTimeout(function(){
          resolve("promise 1");
        }, 200);
      });

      var promise2 = new RSVP.Promise(function(resolve, reject){
        setTimeout(function(){
          resolve("promise 2");
        }, 100);
      });

      RSVP.race([promise1, promise2]).then(function(result){
        // result === "promise 2" because it was resolved before promise1
        // was resolved.
      });
      ```

      `RSVP.race` is deterministic in that only the state of the first completed
      promise matters. For example, even if other promises given to the `promises`
      array argument are resolved, but the first completed promise has become
      rejected before the other promises became fulfilled, the returned promise
      will become rejected:

      ```javascript
      var promise1 = new RSVP.Promise(function(resolve, reject){
        setTimeout(function(){
          resolve("promise 1");
        }, 200);
      });

      var promise2 = new RSVP.Promise(function(resolve, reject){
        setTimeout(function(){
          reject(new Error("promise 2"));
        }, 100);
      });

      RSVP.race([promise1, promise2]).then(function(result){
        // Code here never runs because there are rejected promises!
      }, function(reason){
        // reason.message === "promise2" because promise 2 became rejected before
        // promise 1 became fulfilled
      });
      ```

      @method race
      @for RSVP
      @param {Array} promises array of promises to observe
      @param {String} label optional string for describing the promise returned.
      Useful for tooling.
      @return {Promise} a promise that becomes fulfilled with the value the first
      completed promises is resolved with if the first completed promise was
      fulfilled, or rejected with the reason that the first completed promise
      was rejected with.
    */
    function race(promises) {
      /*jshint validthis:true */
      var Promise = this;

      if (!isArray(promises)) {
        throw new TypeError('You must pass an array to race.');
      }
      return new Promise(function(resolve, reject) {
        var results = [], promise;

        for (var i = 0; i < promises.length; i++) {
          promise = promises[i];

          if (promise && typeof promise.then === 'function') {
            promise.then(resolve, reject);
          } else {
            resolve(promise);
          }
        }
      });
    }

    __exports__.race = race;
  });
define("promise/reject", 
  ["exports"],
  function(__exports__) {
    "use strict";
    /**
      `RSVP.reject` returns a promise that will become rejected with the passed
      `reason`. `RSVP.reject` is essentially shorthand for the following:

      ```javascript
      var promise = new RSVP.Promise(function(resolve, reject){
        reject(new Error('WHOOPS'));
      });

      promise.then(function(value){
        // Code here doesn't run because the promise is rejected!
      }, function(reason){
        // reason.message === 'WHOOPS'
      });
      ```

      Instead of writing the above, your code now simply becomes the following:

      ```javascript
      var promise = RSVP.reject(new Error('WHOOPS'));

      promise.then(function(value){
        // Code here doesn't run because the promise is rejected!
      }, function(reason){
        // reason.message === 'WHOOPS'
      });
      ```

      @method reject
      @for RSVP
      @param {Any} reason value that the returned promise will be rejected with.
      @param {String} label optional string for identifying the returned promise.
      Useful for tooling.
      @return {Promise} a promise that will become rejected with the given
      `reason`.
    */
    function reject(reason) {
      /*jshint validthis:true */
      var Promise = this;

      return new Promise(function (resolve, reject) {
        reject(reason);
      });
    }

    __exports__.reject = reject;
  });
define("promise/resolve", 
  ["exports"],
  function(__exports__) {
    "use strict";
    function resolve(value) {
      /*jshint validthis:true */
      if (value && typeof value === 'object' && value.constructor === this) {
        return value;
      }

      var Promise = this;

      return new Promise(function(resolve) {
        resolve(value);
      });
    }

    __exports__.resolve = resolve;
  });
define("promise/utils", 
  ["exports"],
  function(__exports__) {
    "use strict";
    function objectOrFunction(x) {
      return isFunction(x) || (typeof x === "object" && x !== null);
    }

    function isFunction(x) {
      return typeof x === "function";
    }

    function isArray(x) {
      return Object.prototype.toString.call(x) === "[object Array]";
    }

    // Date.now is not available in browsers < IE9
    // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date/now#Compatibility
    var now = Date.now || function() { return new Date().getTime(); };


    __exports__.objectOrFunction = objectOrFunction;
    __exports__.isFunction = isFunction;
    __exports__.isArray = isArray;
    __exports__.now = now;
  });
requireModule('promise/polyfill').polyfill();
}());
  
});

require.register("eventric/index", function(exports, require, module){
  var _base;

if (typeof (_base = require('es6-promise')).polyfill === "function") {
  _base.polyfill();
}

module.exports = new (require('./eventric'));

  
});

require.register("eventric/aggregate/aggregate", function(exports, require, module){
  
/**
* @name Aggregate
* @module Aggregate
* @description
*
* Aggregates live inside a Context and give you basically transactional boundaries
* for your Behaviors and DomainEvents.
 */
var Aggregate,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Aggregate = (function() {
  function Aggregate(_context, _eventric, _name, Root) {
    this._context = _context;
    this._eventric = _eventric;
    this._name = _name;
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


  /**
  * @name emitDomainEvent
  * @module Aggregate
  * @description Emit DomainEvent
  *
  * @param {String} domainEventName Name of the DomainEvent
  * @param {Object} domainEventPayload Object containing the payload of the DomainEvent
   */

  Aggregate.prototype.emitDomainEvent = function(domainEventName, domainEventPayload) {
    var DomainEventClass, domainEvent, err;
    DomainEventClass = this._context.getDomainEvent(domainEventName);
    if (!DomainEventClass) {
      err = "Tried to emitDomainEvent '" + domainEventName + "' which is not defined";
      this._eventric.log.error(err);
      throw new Error(err);
    }
    domainEvent = this._createDomainEvent(domainEventName, DomainEventClass, domainEventPayload);
    this._domainEvents.push(domainEvent);
    this._handleDomainEvent(domainEventName, domainEvent);
    return this._eventric.log.debug("Created and Handled DomainEvent in Aggregate", domainEvent);
  };

  Aggregate.prototype._createDomainEvent = function(domainEventName, DomainEventClass, domainEventPayload) {
    return new this._eventric.DomainEvent({
      id: this._eventric.generateUid(),
      name: domainEventName,
      aggregate: {
        id: this.id,
        name: this._name
      },
      context: this._context.name,
      payload: new DomainEventClass(domainEventPayload)
    });
  };

  Aggregate.prototype._handleDomainEvent = function(domainEventName, domainEvent) {
    if (this.root["handle" + domainEventName]) {
      return this.root["handle" + domainEventName](domainEvent, function() {});
    } else {
      return this._eventric.log.debug("Tried to handle the DomainEvent '" + domainEventName + "' without a matching handle method");
    }
  };


  /**
  * @name getDomainEvents
  * @module Aggregate
  * @description Get all emitted DomainEvents
   */

  Aggregate.prototype.getDomainEvents = function() {
    return this._domainEvents;
  };


  /**
  * @name applyDomainEvents
  * @module Context
  * @description Apply DomainEvents to the Aggregate
  *
  * @param {Array} domainEvents Array containing DomainEvents
   */

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
    return this.saveAndPublishDomainEvent(domainEvent).then((function(_this) {
      return function() {
        return _this._eventric.log.debug("Created and Handled DomainEvent in Context", domainEvent);
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
    exampleContext.addCommandHandler('someCommand', function(params) {
      // ...
    });
    ```
  * @param {String} commandName Name of the command
  * @param {String} commandFunction The CommandHandler Function
   */

  Context.prototype.addCommandHandler = function(commandHandlerName, commandHandlerFn) {
    this._commandHandlers[commandHandlerName] = commandHandlerFn;
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
    exampleContext.addQueryHandler('SomeQuery', function(params) {
      // ...
    });
    ```
  
  * @param {String} queryHandler Name of the query
  * @param {String} queryFunction Function to execute on query
   */

  Context.prototype.addQueryHandler = function(queryHandlerName, queryHandlerFn) {
    this._queryHandlers[queryHandlerName] = queryHandlerFn;
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
    if (options == null) {
      options = {};
    }
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var domainEventName, domainEventNames, domainEventStream, domainEventStreamId, err, functionName, functionValue;
        if (!_this._domainEventStreamClasses[domainEventStreamName]) {
          err = new Error("DomainEventStream Class with name " + domainEventStreamName + " not added");
          _this.log.error(err);
          return reject(err);
        }
        domainEventStream = new _this._domainEventStreamClasses[domainEventStreamName];
        domainEventStream._domainEventsPublished = {};
        domainEventStreamId = _this._eventric.generateUid();
        _this._domainEventStreamInstances[domainEventStreamId] = domainEventStream;
        domainEventNames = [];
        for (functionName in domainEventStream) {
          functionValue = domainEventStream[functionName];
          if ((functionName.indexOf('filter')) === 0 && (typeof functionValue === 'function')) {
            domainEventName = functionName.replace(/^filter/, '');
            domainEventNames.push(domainEventName);
          }
        }
        _this._applyDomainEventsFromStoreToDomainEventStream(domainEventNames, domainEventStream, handlerFn).then(function() {
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
        })["catch"](function(err) {
          return reject(err);
        });
        return resolve(domainEventStreamId);
      };
    })(this));
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
    exampleContext.addDomainService('DoSomethingSpecial', function(params) {
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

  Context.prototype.initialize = function() {
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
          return resolve();
        })["catch"](function(err) {
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
          return _this._storeInstances[store.name].initialize(_this, store.options).then(function() {
            _this.log.debug("[" + _this.name + "] Finished initializing Store " + store.name);
            return next();
          })["catch"](function(err) {
            return next(err);
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
  * @name saveAndPublishDomainEvent
  * @module Context
  * @description Save a DomainEvent to the default DomainEventStore
  *
  * @param {Object} domainEvent Instance of a DomainEvent
   */

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


  /**
  * @name clearProjectionStore
  * @module Context
  * @description Clear the ProjectionStore
  *
  * @param {String} storeName Name of the Store
  * @param {String} projectionName Name of the Projection
   */

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
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var command, commandHandlerFn, commandPromise, diFn, diFnName, err, _di, _ref;
        command = {
          id: _this._eventric.generateUid(),
          name: commandName,
          params: commandParams
        };
        _this.log.debug('Got Command', command);
        if (!_this._initialized) {
          err = 'Context not initialized yet';
          _this.log.error(err);
          err = new Error(err);
          return reject(err);
        }
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
        commandPromise = null;
        commandHandlerFn = _this._commandHandlers[commandName];
        if (commandHandlerFn.length <= 1) {
          commandPromise = commandHandlerFn.apply(_di, [commandParams]);
          if (!(commandPromise instanceof Promise)) {
            err = "CommandHandler " + commandName + " didnt return a promise and no promise argument defined.";
            _this.log.error(err);
            return reject(err);
          }
        } else {
          commandPromise = new Promise(function(resolve, reject) {
            return commandHandlerFn.apply(_di, [
              commandParams, {
                resolve: resolve,
                reject: reject
              }
            ]);
          });
        }
        return commandPromise.then(function(result) {
          _this.log.debug('Completed Command', commandName);
          return resolve(result);
        })["catch"](function(err) {
          return reject(err);
        });
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
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var err, queryPromise;
        _this.log.debug('Got Query', queryName);
        if (!_this._initialized) {
          err = 'Context not initialized yet';
          _this.log.error(err);
          err = new Error(err);
          reject(err);
          return;
        }
        if (!_this._queryHandlers[queryName]) {
          err = "Given query " + queryName + " not registered on context";
          _this.log.error(err);
          err = new Error(err);
          return reject(err);
        }
        if (_this._queryHandlers[queryName].length <= 1) {
          queryPromise = _this._queryHandlers[queryName].apply(_this._di, [queryParams]);
        } else {
          queryPromise = new Promise(function(resolve, reject) {
            return _this._queryHandlers[queryName].apply(_this._di, [
              queryParams, {
                resolve: resolve,
                reject: reject
              }
            ]);
          });
        }
        return queryPromise.then(function(result) {
          _this.log.debug("Completed Query " + queryName + " with Result " + result);
          return resolve(result);
        })["catch"](function(err) {
          return reject(err);
        });
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

  
});

require.register("eventric/context/index", function(exports, require, module){
  module.exports = require('./context');

  
});

require.register("eventric/domain_event/domain_event", function(exports, require, module){
  
/**
* @name DomainEvent
* @module DomainEvent
* @description
*
* DomainEvents are the most important and most easy building block.
 */
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
  
/**
* @name EventBus
* @module EventBus
* @description
*
* The EventBus handles subscribing and publishing DomainEvents
 */
var EventBus;

EventBus = (function() {
  function EventBus(_eventric) {
    this._eventric = _eventric;
    this._pubSub = new this._eventric.PubSub();
  }


  /**
  * @name subscribeToDomainEvent
  * @module EventBus
  * @description Subscribe to DomainEvents
  *
  * @param {String} eventName The Name of DomainEvent to subscribe to
  * @param {Function} handlerFn Function to handle the DomainEvent
   */

  EventBus.prototype.subscribeToDomainEvent = function(eventName, handlerFn, options) {
    if (options == null) {
      options = {};
    }
    if (options.isAsync) {
      return this._pubSub.subscribeAsync(eventName, handlerFn);
    } else {
      return this._pubSub.subscribe(eventName, handlerFn);
    }
  };


  /**
  * @name subscribeToDomainEventWithAggregateId
  * @module EventBus
  * @description Subscribe to DomainEvents by AggregateId
  *
  * @param {String} eventName The Name of DomainEvent to subscribe to
  * @param {String} aggregateId The AggregateId to subscribe to
  * @param {Function} handlerFn Function to handle the DomainEvent
   */

  EventBus.prototype.subscribeToDomainEventWithAggregateId = function(eventName, aggregateId, handlerFn, options) {
    if (options == null) {
      options = {};
    }
    return this.subscribeToDomainEvent("" + eventName + "/" + aggregateId, handlerFn, options);
  };


  /**
  * @name subscribeToAllDomainEvents
  * @module EventBus
  * @description Subscribe to all DomainEvents
  *
  * @param {Function} handlerFn Function to handle the DomainEvent
   */

  EventBus.prototype.subscribeToAllDomainEvents = function(handlerFn) {
    return this._pubSub.subscribe('DomainEvent', handlerFn);
  };


  /**
  * @name publishDomainEvent
  * @module EventBus
  * @description Publish a DomainEvent on the Bus
   */

  EventBus.prototype.publishDomainEvent = function(domainEvent) {
    return this._publish('publish', domainEvent);
  };


  /**
  * @name publishDomainEventAndWait
  * @module EventBus
  * @description Publish a DomainEvent on the Bus and wait for all Projections to call their promise.resolve
   */

  EventBus.prototype.publishDomainEventAndWait = function(domainEvent) {
    return this._publish('publishAsync', domainEvent);
  };

  EventBus.prototype._publish = function(publishMethod, domainEvent) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        return _this._pubSub[publishMethod]('DomainEvent', domainEvent).then(function() {
          return _this._pubSub[publishMethod](domainEvent.name, domainEvent);
        }).then(function() {
          if (domainEvent.aggregate && domainEvent.aggregate.id) {
            return _this._pubSub[publishMethod]("" + domainEvent.name + "/" + domainEvent.aggregate.id, domainEvent).then(function() {
              return resolve();
            });
          } else {
            return resolve();
          }
        })["catch"](function(err) {
          return reject(err);
        });
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

require.register("eventric/process_manager/index", function(exports, require, module){
  module.exports = require('./process_manager');

  
});

require.register("eventric/process_manager/process_manager", function(exports, require, module){
  
/**
* @name ProcessManager
* @module ProcessManager
* @description
*
* ProcessManagers can handle multiple DomainEvents and have correlation and causation features
 */
var ProcessManagerService;

ProcessManagerService = (function() {
  function ProcessManagerService() {
    this._processManagerInstances = {};
  }


  /**
  * @name add
  * @module ProcessManager
  * @description Add a ProcessManager
  *
  * @param {String} processManagerName Name of the ProcessManager
  * @param {Object} processManagerObject Object containing the ProcessManagerDefinition
   */

  ProcessManagerService.prototype.add = function(processManagerName, processManagerObj, index) {
    var contextName, domainEventName, domainEventNames, _ref, _results;
    _ref = processManagerObj.initializeWhen;
    _results = [];
    for (contextName in _ref) {
      domainEventNames = _ref[contextName];
      _results.push((function() {
        var _i, _len, _results1;
        _results1 = [];
        for (_i = 0, _len = domainEventNames.length; _i < _len; _i++) {
          domainEventName = domainEventNames[_i];
          _results1.push(index.subscribeToDomainEvent(contextName, domainEventName, (function(_this) {
            return function(domainEvent) {
              return _this._spawnProcessManager(processManagerName, processManagerObj["class"], contextName, domainEvent, index);
            };
          })(this)));
        }
        return _results1;
      }).call(this));
    }
    return _results;
  };

  ProcessManagerService.prototype._spawnProcessManager = function(processManagerName, ProcessManagerClass, contextName, domainEvent, index) {
    var handleContextDomainEventNames, key, processManager, processManagerId, value, _base, _base1;
    processManagerId = index.generateUid();
    processManager = new ProcessManagerClass;
    processManager.$endProcess = (function(_this) {
      return function() {
        return _this._endProcessManager(processManagerName, processManagerId);
      };
    })(this);
    handleContextDomainEventNames = [];
    for (key in processManager) {
      value = processManager[key];
      if ((key.indexOf('from')) === 0 && (typeof value === 'function')) {
        handleContextDomainEventNames.push(key);
      }
    }
    this._subscribeProcessManagerToDomainEvents(processManager, handleContextDomainEventNames, index);
    processManager.initialize(domainEvent);
    if ((_base = this._processManagerInstances)[processManagerName] == null) {
      _base[processManagerName] = {};
    }
    if ((_base1 = this._processManagerInstances[processManagerName])[processManagerId] == null) {
      _base1[processManagerId] = {};
    }
    return this._processManagerInstances[processManagerName][processManagerId] = processManager;
  };

  ProcessManagerService.prototype._endProcessManager = function(processManagerName, processManagerId) {
    return delete this._processManagerInstances[processManagerName][processManagerId];
  };

  ProcessManagerService.prototype._subscribeProcessManagerToDomainEvents = function(processManager, handleContextDomainEventNames, index) {
    return index.subscribeToDomainEvent((function(_this) {
      return function(domainEvent) {
        var handleContextDomainEventName, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = handleContextDomainEventNames.length; _i < _len; _i++) {
          handleContextDomainEventName = handleContextDomainEventNames[_i];
          if (("from" + domainEvent.context + "_handle" + domainEvent.name) === handleContextDomainEventName) {
            _results.push(_this._applyDomainEventToProcessManager(handleContextDomainEventName, domainEvent, processManager));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };
    })(this));
  };

  ProcessManagerService.prototype._applyDomainEventToProcessManager = function(handleContextDomainEventName, domainEvent, processManager) {
    var err;
    if (!processManager[handleContextDomainEventName]) {
      return err = new Error("Tried to apply DomainEvent '" + domainEventName + "' to Projection without a matching handle method");
    } else {
      return processManager[handleContextDomainEventName](domainEvent);
    }
  };

  return ProcessManagerService;

})();

module.exports = new ProcessManagerService;

  
});

require.register("eventric/projection/index", function(exports, require, module){
  module.exports = require('./projection');

  
});

require.register("eventric/projection/projection", function(exports, require, module){
  
/**
* @name Projection
* @module Projection
* @description
*
* Projections can handle muliple DomainEvents and built a denormalized state based on them
 */
var Projection,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Projection = (function() {
  function Projection(_eventric) {
    this._eventric = _eventric;
    this._applyDomainEventToProjection = __bind(this._applyDomainEventToProjection, this);
    this.log = this._eventric.log;
    this._handlerFunctions = {};
    this._projectionInstances = {};
    this._domainEventsApplied = {};
  }


  /**
  * @name initializeInstance
  * @module Projection
  * @description Initialize a ProjectionInstance
  *
  * @param {String} projectionName Name of the Projection
  * @param {Function|Object} Projection Function or Object containing a ProjectionDefinition
   */

  Projection.prototype.initializeInstance = function(projectionName, Projection, params, _context) {
    this._context = _context;
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var aggregateId, diFn, diName, domainEventStreamName, projection, projectionId, _ref;
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
        domainEventStreamName = null;
        projection.$subscribeToDomainEventStream = function(_domainEventStreamName) {
          return domainEventStreamName = _domainEventStreamName;
        };
        _this.log.debug("[" + _this._context.name + "] Clearing ProjectionStores " + projection.stores + " of " + projectionName);
        return _this._clearProjectionStores(projection.stores, projectionName).then(function() {
          _this.log.debug("[" + _this._context.name + "] Finished clearing ProjectionStores of " + projectionName);
          return _this._injectStoresIntoProjection(projectionName, projection);
        }).then(function() {
          return _this._callInitializeOnProjection(projectionName, projection, params);
        }).then(function() {
          _this.log.debug("[" + _this._context.name + "] Replaying DomainEvents against Projection " + projectionName);
          return _this._parseEventNamesFromProjection(projection);
        }).then(function(eventNames) {
          return _this._applyDomainEventsFromStoreToProjection(projectionId, projection, eventNames, aggregateId);
        }).then(function(eventNames) {
          _this.log.debug("[" + _this._context.name + "] Finished Replaying DomainEvents against Projection " + projectionName);
          return _this._subscribeProjectionToDomainEvents(projectionId, projectionName, projection, eventNames, aggregateId, domainEventStreamName);
        }).then(function() {
          var event;
          _this._projectionInstances[projectionId] = projection;
          event = {
            id: projectionId,
            projection: projection
          };
          _this._context.publish("projection:" + projectionName + ":initialized", event);
          _this._context.publish("projection:" + projectionId + ":initialized", event);
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
    return new Promise((function(_this) {
      return function(resolve, reject) {
        if (!projection.stores) {
          return resolve();
        }
        if (projection["$store"] == null) {
          projection["$store"] = {};
        }
        return _this._eventric.eachSeries(projection.stores, function(projectionStoreName, next) {
          _this.log.debug("[" + _this._context.name + "] Injecting ProjectionStore " + projectionStoreName + " into Projection " + projectionName);
          return _this._context.getProjectionStore(projectionStoreName, projectionName).then(function(projectionStore) {
            if (projectionStore) {
              projection["$store"][projectionStoreName] = projectionStore;
              _this.log.debug("[" + _this._context.name + "] Finished Injecting ProjectionStore " + projectionStoreName + " into Projection " + projectionName);
              return next();
            }
          })["catch"](function(err) {
            return next(err);
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

  Projection.prototype._clearProjectionStores = function(projectionStores, projectionName) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        if (!projectionStores) {
          return resolve();
        }
        return _this._eventric.eachSeries(projectionStores, function(projectionStoreName, next) {
          _this.log.debug("[" + _this._context.name + "] Clearing ProjectionStore " + projectionStoreName + " for " + projectionName);
          return _this._context.clearProjectionStore(projectionStoreName, projectionName).then(function() {
            _this.log.debug("[" + _this._context.name + "] Finished clearing ProjectionStore " + projectionStoreName + " for " + projectionName);
            return next();
          })["catch"](function(err) {
            return next(err);
          });
        }, function(err) {
          return resolve();
        });
      };
    })(this));
  };

  Projection.prototype._parseEventNamesFromProjection = function(projection) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
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
      };
    })(this));
  };

  Projection.prototype._applyDomainEventsFromStoreToProjection = function(projectionId, projection, eventNames, aggregateId) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var findEvents;
        _this._domainEventsApplied[projectionId] = {};
        if (aggregateId) {
          findEvents = _this._context.findDomainEventsByNameAndAggregateId(eventNames, aggregateId);
        } else {
          findEvents = _this._context.findDomainEventsByName(eventNames);
        }
        return findEvents.then(function(domainEvents) {
          if (!domainEvents || domainEvents.length === 0) {
            return resolve(eventNames);
          }
          return _this._eventric.eachSeries(domainEvents, function(domainEvent, next) {
            return _this._applyDomainEventToProjection(domainEvent, projection).then(function() {
              _this._domainEventsApplied[projectionId][domainEvent.id] = true;
              return next();
            });
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

  Projection.prototype._subscribeProjectionToDomainEvents = function(projectionId, projectionName, projection, eventNames, aggregateId, domainEventStreamName) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var domainEventHandler;
        domainEventHandler = function(domainEvent, done) {
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
            _this._context.publish("projection:" + projectionName + ":changed", event);
            _this._context.publish("projection:" + projectionId + ":changed", event);
            return done();
          })["catch"](function(err) {
            return done(err);
          });
        };
        if (domainEventStreamName) {
          return _this._context.subscribeToDomainEventStream(domainEventStreamName, domainEventHandler, {
            isAsync: true
          }).then(function(subscriberId) {
            var _base;
            if ((_base = _this._handlerFunctions)[projectionId] == null) {
              _base[projectionId] = [];
            }
            _this._handlerFunctions[projectionId].push(subscriberId);
            return resolve();
          })["catch"](function(err) {
            return reject(err);
          });
        } else {
          return _this._eventric.eachSeries(eventNames, function(eventName, done) {
            var subscriberPromise;
            if (aggregateId) {
              subscriberPromise = _this._context.subscribeToDomainEventWithAggregateId(eventName, aggregateId, domainEventHandler, {
                isAsync: true
              });
            } else {
              subscriberPromise = _this._context.subscribeToDomainEvent(eventName, domainEventHandler, {
                isAsync: true
              });
            }
            return subscriberPromise.then(function(subscriberId) {
              var _base;
              if ((_base = _this._handlerFunctions)[projectionId] == null) {
                _base[projectionId] = [];
              }
              _this._handlerFunctions[projectionId].push(subscriberId);
              return done();
            })["catch"](function(err) {
              return done(err);
            });
          }, function(err) {
            if (err) {
              return reject(err);
            }
            return resolve();
          });
        }
      };
    })(this));
  };

  Projection.prototype._applyDomainEventToProjection = function(domainEvent, projection) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        if (!projection["handle" + domainEvent.name]) {
          _this.log.debug("Tried to apply DomainEvent '" + domainEvent.name + "' to Projection without a matching handle method");
          return resolve();
        }
        if (projection["handle" + domainEvent.name].length === 2) {
          return projection["handle" + domainEvent.name](domainEvent, {
            resolve: resolve,
            reject: reject
          });
        } else {
          projection["handle" + domainEvent.name](domainEvent);
          return resolve();
        }
      };
    })(this));
  };


  /**
  * @name getInstance
  * @module Projection
  * @description Get a ProjectionInstance
  *
  * @param {String} projectionId ProjectionId
   */

  Projection.prototype.getInstance = function(projectionId) {
    return this._projectionInstances[projectionId];
  };


  /**
  * @name destroyInstance
  * @module Projection
  * @description Destroy a ProjectionInstance
  *
  * @param {String} projectionId ProjectionId
  * @param {Object} context Context Instance so we can automatically unsubscribe the Projection from DomainEvents
   */

  Projection.prototype.destroyInstance = function(projectionId) {
    var subscriberId, unsubscribePromises, _i, _len, _ref;
    if (!this._handlerFunctions[projectionId]) {
      return this._eventric.log.error('Missing attribute projectionId');
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
  
/**
* @name PubSub
* @module PubSub
* @description
*
* Publish and Subscribe to arbitrary Events
 */
var PubSub,
  __slice = [].slice;

PubSub = (function() {
  function PubSub() {
    this._subscribers = [];
    this._subscriberId = 0;
    this._nextTick = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return setTimeout.apply(null, args);
    };
  }


  /**
  * @name subscribe
  * @module PubSub
  * @description Subscribe to an Event
  *
  * @param {String} eventName Name of the Event to subscribe to
  * @param {Function} subscriberFn Function to call when Event gets published
   */

  PubSub.prototype.subscribe = function(eventName, subscriberFn) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var subscriber;
        subscriber = {
          eventName: eventName,
          subscriberFn: subscriberFn,
          subscriberId: _this._getNextSubscriberId()
        };
        _this._subscribers.push(subscriber);
        return resolve(subscriber.subscriberId);
      };
    })(this));
  };


  /**
  * @name subscribeAsync
  * @module PubSub
  * @description Subscribe asynchronously to an Event
  *
  * @param {String} eventName Name of the Event to subscribe to
  * @param {Function} subscriberFn Function to call when Event gets published
   */

  PubSub.prototype.subscribeAsync = function(eventName, subscriberFn) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var subscriber;
        subscriber = {
          eventName: eventName,
          subscriberFn: subscriberFn,
          subscriberId: _this._getNextSubscriberId(),
          isAsync: true
        };
        _this._subscribers.push(subscriber);
        return resolve(subscriber.subscriberId);
      };
    })(this));
  };


  /**
  * @name publish
  * @module PubSub
  * @description Publish an Event
  *
  * @param {String} eventName Name of the Event
  * @param {Object} payload The Event payload to be published
   */

  PubSub.prototype.publish = function(eventName, payload) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var executeNextHandler, subscribers;
        subscribers = _this._getRelevantSubscribers(eventName);
        executeNextHandler = function() {
          if (subscribers.length === 0) {
            return resolve();
          } else {
            subscribers.shift().subscriberFn(payload, function() {});
            return _this._nextTick(executeNextHandler, 0);
          }
        };
        return _this._nextTick(executeNextHandler, 0);
      };
    })(this));
  };


  /**
  * @name publishAsync
  * @module PubSub
  * @description Publish an Event
  *
  * @param {String} eventName Name of the Event
  * @param {Object} payload The Event payload to asynchronously be published
   */

  PubSub.prototype.publishAsync = function(eventName, payload) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var executeNextHandler, subscribers;
        subscribers = _this._getRelevantSubscribers(eventName);
        executeNextHandler = function() {
          var subscriber;
          if (subscribers.length === 0) {
            return resolve();
          } else {
            subscriber = subscribers.shift();
            if (subscriber.isAsync) {
              return subscriber.subscriberFn(payload, function() {
                return setTimeout(executeNextHandler, 0);
              });
            } else {
              subscriber.subscriberFn(payload);
              return _this._nextTick(executeNextHandler, 0);
            }
          }
        };
        return _this._nextTick(executeNextHandler, 0);
      };
    })(this));
  };

  PubSub.prototype._getRelevantSubscribers = function(eventName) {
    if (eventName) {
      return this._subscribers.filter(function(x) {
        return x.eventName === eventName;
      });
    } else {
      return this._subscribers;
    }
  };


  /**
  * @name unsubscribe
  * @module PubSub
  * @description Unscribe from an Event
  *
  * @param {String} subscriberId SubscriberId
   */

  PubSub.prototype.unsubscribe = function(subscriberId) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        _this._subscribers = _this._subscribers.filter(function(x) {
          return x.subscriberId !== subscriberId;
        });
        return resolve();
      };
    })(this));
  };

  PubSub.prototype._getNextSubscriberId = function() {
    return this._subscriberId++;
  };

  return PubSub;

})();

module.exports = PubSub;

  
});

require.register("eventric/remote/index", function(exports, require, module){
  module.exports = require('./remote');

  
});

require.register("eventric/remote/remote", function(exports, require, module){
  
/**
* @name Remote
* @module Remote
* @description
*
* Remotes let you remotely use Contexts
 */
var Remote;

Remote = (function() {
  function Remote(_contextName, _eventric) {
    this._contextName = _contextName;
    this._eventric = _eventric;
    this.name = this._contextName;
    this.InMemoryRemote = require('./inmemory');
    this._params = {};
    this._clients = {};
    this._projectionClasses = {};
    this._projectionInstances = {};
    this._handlerFunctions = {};
    this.projectionService = new this._eventric.Projection(this._eventric);
    this.addClient('inmemory', this.InMemoryRemote.client);
    this.set('default client', 'inmemory');
  }


  /**
  * @name set
  * @module Remote
  * @description Configure Remote parameters
  *
  * @example
  
     exampleRemote.set 'store', StoreAdapter
  
  *
  * @param {String} key Name of the key
  * @param {Mixed} value Value to be set
   */

  Remote.prototype.set = function(key, value) {
    this._params[key] = value;
    return this;
  };


  /**
  * @name get
  * @module Remote
  * @description Get configured Remote parameters
  *
  * @example
  
     exampleRemote.set 'store', StoreAdapter
  
  *
  * @param {String} key Name of the Key
   */

  Remote.prototype.get = function(key) {
    return this._params[key];
  };


  /**
  * @name command
  * @module Remote
  * @description Execute previously added CommandHandlers
  *
  * @example
    ```javascript
    exampleRemote.command('doSomething');
    ```
  *
  * @param {String} `commandName` Name of the CommandHandler to be executed
  * @param {Object} `commandParams` Parameters for the CommandHandler function
   */

  Remote.prototype.command = function() {
    return this._rpc('command', arguments);
  };


  /**
  * @name query
  * @module Remote
  * @description Execute previously added QueryHandler
  *
  * @example
    ```javascript
    exampleRemote.query('getSomething');
    ```
  *
  * @param {String} `queryName` Name of the QueryHandler to be executed
  * @param {Object} `queryParams` Parameters for the QueryHandler function
   */

  Remote.prototype.query = function() {
    return this._rpc('query', arguments);
  };


  /**
  * @name findAllDomainEvents
  * @module Remote
  * @description Return all DomainEvents from the default DomainEventStore
   */

  Remote.prototype.findAllDomainEvents = function() {
    return this._rpc('findAllDomainEvents', arguments);
  };


  /**
  * @name findDomainEventsByName
  * @module Remote
  * @description Return DomainEvents from the default DomainEventStore which match the given DomainEventName
  *
  * @param {String} domainEventName Name of the DomainEvent to be returned
   */

  Remote.prototype.findDomainEventsByName = function() {
    return this._rpc('findDomainEventsByName', arguments);
  };


  /**
  * @name findDomainEventsByAggregateId
  * @module Remote
  * @description Return DomainEvents from the default DomainEventStore which match the given AggregateId
  *
  * @param {String} aggregateId AggregateId of the DomainEvents to be found
   */

  Remote.prototype.findDomainEventsByAggregateId = function() {
    return this._rpc('findDomainEventsByAggregateId', arguments);
  };


  /**
  * @name findDomainEventsByAggregateName
  * @module Remote
  * @description Return DomainEvents from the default DomainEventStore which match the given AggregateName
  *
  * @param {String} aggregateName AggregateName of the DomainEvents to be found
   */

  Remote.prototype.findDomainEventsByAggregateName = function() {
    return this._rpc('findDomainEventsByAggregateName', arguments);
  };


  /**
  * @name findDomainEventsByNameAndAggregateId
  * @module Remote
  * @description Return DomainEvents from the default DomainEventStore which match the given DomainEventName and AggregateId
  *
  * @param {String} domainEventName Name of the DomainEvents to be found
  * @param {String} aggregateId AggregateId of the DomainEvents to be found
   */

  Remote.prototype.findDomainEventsByNameAndAggregateId = function() {
    return this._rpc('findDomainEventsByNameAndAggregateId', arguments);
  };


  /**
  * @name subscribeToAllDomainEvents
  * @module Remote
  * @description Add handler function which gets called when any `DomainEvent` gets triggered
  *
  * @param {Function} Function which gets called with `domainEvent` as argument
   */

  Remote.prototype.subscribeToAllDomainEvents = function(handlerFn) {
    return this._rps('subscribeToAllDomainEvents', handlerFn);
  };


  /**
  * @name subscribeToDomainEvent
  * @module Remote
  * @description Add handler function which gets called when a specific `DomainEvent` gets triggered
  *
  * @example
    ```javascript
    exampleRemote.subscribeToDomainEvent('SomethingHappened', function(domainEvent) {
      // ...
    });
    ```
  *
  * @param {String} domainEventName Name of the `DomainEvent`
  * @param {Function} Function which gets called with `domainEvent` as argument
   */

  Remote.prototype.subscribeToDomainEvent = function(domainEventName, handlerFn) {
    return this._rps('subscribeToDomainEvent', handlerFn, [domainEventName]);
  };


  /**
  * @name subscribeToDomainEventWithAggregateId
  * @module Remote
  * @description Add handler function which gets called when a specific `DomainEvent` containing a specific AggregateId gets triggered
  *
  * @param {String} domainEventName Name of the `DomainEvent`
  * @param {String} aggregateId AggregateId
  * @param {Function} Function which gets called with `domainEvent` as argument
   */

  Remote.prototype.subscribeToDomainEventWithAggregateId = function(domainEventName, aggregateId, handlerFn) {
    return this._rps('subscribeToDomainEventWithAggregateId', handlerFn, [domainEventName, aggregateId]);
  };


  /**
  * @name subscribeToDomainEventWithAggregateId
  * @module Remote
  * @description Add handler function which gets called when a specific `DomainEvent` containing a specific AggregateId gets triggered
  *
  * @param {String} domainEventStreamName Name of the `DomainEvent`
  * @param {Function} Function which gets called with `domainEvent` as argument
   */

  Remote.prototype.subscribeToDomainEventStream = function() {
    return this._rpc('subscribeToDomainEventStream', arguments);
  };


  /**
  * @name unsubscribeFromDomainEvent
  * @module Remote
  * @description Unsubscribe from a DomainEvent
  *
  * @param {String} subscriber SubscriberId
   */

  Remote.prototype.unsubscribeFromDomainEvent = function(subscriberId) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.unsubscribe(subscriberId);
  };

  Remote.prototype._rps = function(method, subscriberFn, params) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.subscribe({
      contextName: this._contextName,
      method: method,
      params: params
    }, {
      id: this._eventric.generateUid(),
      fn: subscriberFn
    });
  };

  Remote.prototype._rpc = function(method, params) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.rpc({
      contextName: this._contextName,
      method: method,
      params: Array.prototype.slice.call(params)
    });
  };


  /**
  * @name addClient
  * @module Remote
  * @description Add a RemoteClient
  *
  * @param {String} clientName Name of the Client
  * @param {Object} client Object containing an initialized Client
   */

  Remote.prototype.addClient = function(clientName, client) {
    this._clients[clientName] = client;
    return this;
  };


  /**
  * @name getClient
  * @module Remote
  * @description Get a RemoteClient
  *
  * @param {String} clientName Name of the Client
   */

  Remote.prototype.getClient = function(clientName) {
    return this._clients[clientName];
  };


  /**
  * @name addProjection
  * @module Remote
  * @description Add Projection that can subscribe to and handle DomainEvents
  *
  * @param {string} projectionName Name of the Projection
  * @param {Function} The Projection Class definition
   */

  Remote.prototype.addProjection = function(projectionName, projectionClass) {
    this._projectionClasses[projectionName] = projectionClass;
    return this;
  };


  /**
  * @name initializeProjection
  * @module Remote
  * @description Initialize a Projection based on an Object
  *
  * @param {Object} projectionObject Projection Object
  * @param {Object} params Object containing Projection Parameters
   */

  Remote.prototype.initializeProjection = function(projectionObject, params) {
    return this.projectionService.initializeInstance('', projectionObject, params, this);
  };


  /**
  * @name initializeProjectionInstance
  * @module Remote
  * @description Initialize a ProjectionInstance
  *
  * @param {String} projectionId ProjectionId
  * @param {Object} params Object containing Projection Parameters
   */

  Remote.prototype.initializeProjectionInstance = function(projectionName, params) {
    var err;
    if (!this._projectionClasses[projectionName]) {
      err = "Given projection " + projectionName + " not registered on remote";
      this._eventric.log.error(err);
      err = new Error(err);
      return err;
    }
    return this.projectionService.initializeInstance(projectionName, this._projectionClasses[projectionName], params, this);
  };


  /**
  * @name getProjectionInstance
  * @module Remote
  * @description Get a Projection Instance
  *
  * @param {String} projectionId ProjectionId
   */

  Remote.prototype.getProjectionInstance = function(projectionId) {
    return this.projectionService.getInstance(projectionId);
  };


  /**
  * @name destroyProjectionInstance
  * @module Remote
  * @description Destroy a ProjectionInstance
  *
  * @param {String} projectionId ProjectionId
   */

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
  
/**
* @name Repository
* @module Repository
* @description
*
* The Repository is responsible for creating, saving and finding Aggregates
 */
var Repository,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Repository = (function() {
  function Repository(params, _eventric) {
    this._eventric = _eventric;
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


  /**
  * @name findById
  * @module Repository
  * @description Find an aggregate by its id
  *
  * @param {String} aggregateId The AggregateId of the Aggregate to be found
   */

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
    return this._store.findDomainEventsByAggregateId(aggregateId, (function(_this) {
      return function(err, domainEvents) {
        if (err) {
          return callback(err, null);
        }
        if (domainEvents.length === 0) {
          return callback(null, []);
        }
        return callback(null, domainEvents);
      };
    })(this));
  };


  /**
  * @name create
  * @module Repository
  * @description Create an Aggregate
   */

  Repository.prototype.create = function(params) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var aggregate, commandId, createPromise, err, _base, _ref;
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
        createPromise = new Promise(function(resolve, reject) {
          if (aggregate.root.create.length <= 1) {
            aggregate.root.create(params);
            return resolve();
          } else {
            return aggregate.root.create(params, {
              resolve: resolve,
              reject: reject
            });
          }
        });
        return createPromise.then(function() {
          return resolve(aggregate.root);
        })["catch"](function(err) {
          return reject(err);
        });
      };
    })(this));
  };


  /**
  * @name save
  * @module Repository
  * @description Save the Aggregate
  *
  * @param {String} aggregateId The AggregateId of the Aggregate to be saved
   */

  Repository.prototype.save = function(aggregateId, callback) {
    if (callback == null) {
      callback = function() {};
    }
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var aggregate, commandId, domainEvents, err, _ref;
        commandId = (_ref = _this._command.id) != null ? _ref : 'nocommand';
        aggregate = _this._aggregateInstances[commandId][aggregateId];
        if (!aggregate) {
          err = "Tried to save unknown aggregate " + _this._aggregateName;
          _this._eventric.log.error(err);
          err = new Error(err);
          if (typeof callback === "function") {
            callback(err, null);
          }
          reject(err);
          return;
        }
        domainEvents = aggregate.getDomainEvents();
        if (domainEvents.length < 1) {
          err = "Tried to save 0 DomainEvents from Aggregate " + _this._aggregateName;
          _this._eventric.log.debug(err, _this._command);
          err = new Error(err);
          if (typeof callback === "function") {
            callback(err, null);
          }
          reject(err);
          return;
        }
        _this._eventric.log.debug("Going to Save and Publish " + domainEvents.length + " DomainEvents from Aggregate " + _this._aggregateName);
        return _this._eventric.eachSeries(domainEvents, function(domainEvent, next) {
          domainEvent.command = _this._command;
          return _this._store.saveDomainEvent(domainEvent).then(function() {
            _this._eventric.log.debug("Saved DomainEvent", domainEvent);
            return next(null);
          });
        }, function(err) {
          var publishMethod;
          if (err) {
            callback(err, null);
            return reject(err);
          } else {
            publishMethod = _this._context.isWaitingModeEnabled() ? 'publishDomainEventAndWait' : 'publishDomainEvent';
            return _this._eventric.eachSeries(domainEvents, function(domainEvent, next) {
              _this._eventric.log.debug("Publishing DomainEvent with " + publishMethod, domainEvent);
              return _this._context.getEventBus()[publishMethod](domainEvent).then(function() {
                return next();
              });
            }, function(err) {
              if (err) {
                callback(err, null);
                return reject(err);
              } else {
                resolve(aggregate.id);
                return callback(null, aggregate.id);
              }
            });
          }
        });
      };
    })(this));
  };


  /**
  * @name setCommand
  * @module Repository
  * @description Set the command which is currently processed
  *
  * @param {Object} command The command Object
   */

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
  var InMemoryRemoteClient, InMemoryRemoteEndpoint, PubSub, customRemoteBridge, getFullEventName, pubSub, subscribers,
  __slice = [].slice;

PubSub = require('../../pub_sub');

customRemoteBridge = null;

subscribers = {};

pubSub = new PubSub;

InMemoryRemoteEndpoint = (function() {
  function InMemoryRemoteEndpoint() {
    customRemoteBridge = (function(_this) {
      return function(rpcRequest) {
        return _this._handleRPCRequest(rpcRequest);
      };
    })(this);
  }


  /**
  * @name setRPCHandler
  *
  * @module InMemoryRemoteEndpoint
   */

  InMemoryRemoteEndpoint.prototype.setRPCHandler = function(_handleRPCRequest) {
    this._handleRPCRequest = _handleRPCRequest;
  };


  /**
  * @name publish
  *
  * @module InMemoryRemoteEndpoint
   */

  InMemoryRemoteEndpoint.prototype.publish = function() {
    var aggregateId, contextName, domainEventName, fullEventName, payload, _arg, _i;
    contextName = arguments[0], _arg = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), payload = arguments[_i++];
    domainEventName = _arg[0], aggregateId = _arg[1];
    fullEventName = getFullEventName(contextName, domainEventName, aggregateId);
    return pubSub.publish(fullEventName, payload, function() {});
  };

  return InMemoryRemoteEndpoint;

})();

module.exports.endpoint = new InMemoryRemoteEndpoint;

InMemoryRemoteClient = (function() {
  function InMemoryRemoteClient() {}


  /**
  * @name rpc
  *
  * @module InMemoryRemoteClient
   */

  InMemoryRemoteClient.prototype.rpc = function(rpcRequest) {
    if (!customRemoteBridge) {
      throw new Error('No Remote Endpoint available for in memory client');
    }
    return customRemoteBridge(rpcRequest);
  };

  InMemoryRemoteClient.prototype.subscribe = function(rpcRequest, subscriber) {
    rpcRequest.params.push(subscriber.fn);
    return customRemoteBridge(rpcRequest);
  };


  /**
  * @name unsubscribe
  *
  * @module InMemoryRemoteClient
   */

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
    var options, _arg, _context;
    _context = arguments[0], _arg = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    this._context = _context;
    options = _arg[0];
    return new Promise((function(_this) {
      return function(resolve, reject) {
        _this._domainEventsCollectionName = "" + _this._context.name + ".DomainEvents";
        _this._projectionCollectionName = "" + _this._context.name + ".Projections";
        _this._domainEvents[_this._domainEventsCollectionName] = [];
        return resolve();
      };
    })(this));
  };


  /**
  * @name saveDomainEvent
  *
  * @module InMemoryStore
   */

  InMemoryStore.prototype.saveDomainEvent = function(domainEvent, callback) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        _this._domainEvents[_this._domainEventsCollectionName].push(domainEvent);
        return resolve(domainEvent);
      };
    })(this));
  };


  /**
  * @name findAllDomainEvents
  *
  * @module InMemoryStore
   */

  InMemoryStore.prototype.findAllDomainEvents = function(callback) {
    return callback(null, this._domainEvents[this._domainEventsCollectionName]);
  };


  /**
  * @name findDomainEventsByName
  *
  * @module InMemoryStore
   */

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


  /**
  * @name findDomainEventsByNameAndAggregateId
  *
  * @module InMemoryStore
   */

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


  /**
  * @name findDomainEventsByAggregateId
  *
  * @module InMemoryStore
   */

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


  /**
  * @name findDomainEventsByAggregateName
  *
  * @module InMemoryStore
   */

  InMemoryStore.prototype.findDomainEventsByAggregateName = function(aggregateName, callback) {
    var checkFn, events;
    if (aggregateName instanceof Array) {
      checkFn = function(eventAggregateName) {
        return (aggregateName.indexOf(eventAggregateName)) > -1;
      };
    } else {
      checkFn = function(eventAggregateName) {
        return eventAggregateName === aggregateName;
      };
    }
    events = this._domainEvents[this._domainEventsCollectionName].filter(function(event) {
      var _ref;
      return checkFn((_ref = event.aggregate) != null ? _ref.name : void 0);
    });
    return callback(null, events);
  };


  /**
  * @name getProjectionStore
  *
  * @module InMemoryStore
   */

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


  /**
  * @name clearProjectionStore
  *
  * @module InMemoryStore
   */

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


  /**
  * @name checkSupport
  *
  * @module InMemoryStore
   */

  InMemoryStore.prototype.checkSupport = function(check) {
    return (STORE_SUPPORTS.indexOf(check)) > -1;
  };

  return InMemoryStore;

})();

module.exports = InMemoryStore;

  
});
