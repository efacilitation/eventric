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
require.register("eventric/index", function(exports, require, module){
  module.exports = require('./src');

  
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

require.register("eventric/src/aggregate", function(exports, require, module){
  var Aggregate, DomainEvent, eventric,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __slice = [].slice;

eventric = require('eventric');

DomainEvent = require('./domain_event');

Aggregate = (function() {
  function Aggregate(_context, _name, Root) {
    this._context = _context;
    this._name = _name;
    this.create = __bind(this.create, this);
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
    var DomainEventClass, domainEvent, err;
    DomainEventClass = this._context.getDomainEvent(domainEventName);
    if (!DomainEventClass) {
      err = "Tried to emitDomainEvent '" + domainEventName + "' which is not defined";
      eventric.log.error(err);
      throw new Error(err);
    }
    domainEvent = this._createDomainEvent(domainEventName, DomainEventClass, domainEventPayload);
    this._domainEvents.push(domainEvent);
    this._handleDomainEvent(domainEventName, domainEvent);
    return eventric.log.debug("Created and Handled DomainEvent in Aggregate", domainEvent);
  };

  Aggregate.prototype._createDomainEvent = function(domainEventName, DomainEventClass, domainEventPayload) {
    return new DomainEvent({
      id: eventric.generateUid(),
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
      return eventric.log.debug("Tried to handle the DomainEvent '" + domainEventName + "' without a matching handle method");
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

  Aggregate.prototype.create = function() {
    var params;
    params = arguments;
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var check, e, err, _ref;
        _this.id = eventric.generateUid();
        if (typeof _this.root.create !== 'function') {
          err = "No create function on aggregate";
          eventric.log.error(err);
          throw new Error(err);
        }
        try {
          check = (_ref = _this.root).create.apply(_ref, __slice.call(params).concat([function(err) {
            if (err) {
              return reject(err);
            } else {
              return resolve(_this);
            }
          }]));
          if (check instanceof Promise) {
            check.then(function() {
              return resolve(_this);
            });
            return check["catch"](function(err) {
              return reject(err);
            });
          }
        } catch (_error) {
          e = _error;
          return reject(e);
        }
      };
    })(this));
  };

  return Aggregate;

})();

module.exports = Aggregate;

  
});

require.register("eventric/src/context", function(exports, require, module){
  var Context, DomainEvent, EventBus, PubSub, Repository, eventric, projectionService,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

eventric = require('eventric');

Repository = require('./repository');

EventBus = require('./event_bus');

DomainEvent = require('./domain_event');

PubSub = require('./pub_sub');

projectionService = require('./projection');

Context = (function(_super) {
  __extends(Context, _super);

  function Context(name) {
    this.name = name;
    this.clearProjectionStore = __bind(this.clearProjectionStore, this);
    this.getProjectionStore = __bind(this.getProjectionStore, this);
    this.emitDomainEvent = __bind(this.emitDomainEvent, this);
    Context.__super__.constructor.apply(this, arguments);
    this._initialized = false;
    this._params = eventric.get();
    this._di = {};
    this._aggregateRootClasses = {};
    this._adapterClasses = {};
    this._adapterInstances = {};
    this._commandHandlers = {};
    this._queryHandlers = {};
    this._domainEventClasses = {};
    this._domainEventHandlers = {};
    this._projectionClasses = [];
    this._repositoryInstances = {};
    this._domainServices = {};
    this._storeClasses = {};
    this._storeInstances = {};
    this._eventBus = new EventBus;
  }

  Context.prototype.log = eventric.log;


  /**
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
   */

  Context.prototype.set = function(key, value) {
    this._params[key] = value;
    return this;
  };

  Context.prototype.get = function(key) {
    return this._params[key];
  };


  /**
  * @name emitDomainEvent
  *
  * @description emit Domain Event in the context
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
        return _this._eventBus.publishDomainEvent(domainEvent, function() {});
      };
    })(this));
  };

  Context.prototype._createDomainEvent = function(domainEventName, DomainEventClass, domainEventPayload) {
    return new DomainEvent({
      id: eventric.generateUid(),
      name: domainEventName,
      context: this.name,
      payload: new DomainEventClass(domainEventPayload)
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


  /**
  * @name defineDomainEvent
  *
  * @description
  * Adds a DomainEvent Class which will be used when emitting or handling DomainEvents inside of Aggregates, Projectionpr or ProcessManagers
  *
  * @param {String} domainEventName Name of the DomainEvent
  * @param {Function} DomainEventClass DomainEventClass
   */

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


  /**
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
   */

  Context.prototype.addCommandHandler = function(commandHandlerName, commandHandlerFn) {
    this._commandHandlers[commandHandlerName] = (function(_this) {
      return function() {
        var command, diFn, diFnName, repositoryCache, _di, _ref, _ref1;
        command = {
          id: eventric.generateUid(),
          name: commandHandlerName,
          params: (_ref = arguments[0]) != null ? _ref : null
        };
        _di = {};
        _ref1 = _this._di;
        for (diFnName in _ref1) {
          diFn = _ref1[diFnName];
          _di[diFnName] = diFn;
        }
        repositoryCache = null;
        _di.$repository = function(aggregateName) {
          var AggregateRoot, repository;
          if (!repositoryCache) {
            AggregateRoot = _this._aggregateRootClasses[aggregateName];
            repository = new Repository({
              aggregateName: aggregateName,
              AggregateRoot: AggregateRoot,
              context: _this
            });
            repositoryCache = repository;
          }
          repositoryCache.setCommand(command);
          return repositoryCache;
        };
        return commandHandlerFn.apply(_di, arguments);
      };
    })(this);
    return this;
  };

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
   */

  Context.prototype.addQueryHandler = function(queryHandlerName, queryHandlerFn) {
    this._queryHandlers[queryHandlerName] = (function(_this) {
      return function() {
        return queryHandlerFn.apply(_this._di, arguments);
      };
    })(this);
    return this;
  };

  Context.prototype.addQueryHandlers = function(commandObj) {
    var queryFunction, queryHandlerName;
    for (queryHandlerName in commandObj) {
      queryFunction = commandObj[queryHandlerName];
      this.addQueryHandler(queryHandlerName, queryFunction);
    }
    return this;
  };


  /**
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
   */

  Context.prototype.addAggregate = function(aggregateName, AggregateRootClass) {
    this._aggregateRootClasses[aggregateName] = AggregateRootClass;
    return this;
  };

  Context.prototype.addAggregates = function(aggregatesObj) {
    var AggregateRootClass, aggregateName;
    for (aggregateName in aggregatesObj) {
      AggregateRootClass = aggregatesObj[aggregateName];
      this.addAggregate(aggregateName, AggregateRootClass);
    }
    return this;
  };


  /**
  *
  * @name subscribeToDomainEvent
  *
  * @description
  * Use as: subscribeToDomainEvent(domainEventName, domainEventHandlerFunction)
  *
  * Add handler function which gets called when a specific `DomainEvent` gets triggered
  *
  * @example
    ```javascript
    exampleContext.subscribeToDomainEvent('Example:create', function(domainEvent) {
      // ...
    });
    ```
  *
  * @param {String} domainEventName Name of the `DomainEvent`
  *
  * @param {Function} Function which gets called with `domainEvent` as argument
  * - `domainEvent` Instance of [[DomainEvent]]
  *
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
    this._eventBus.subscribeToDomainEvent(domainEventName, domainEventHandler, options);
    return this;
  };


  /**
  *
  * @name subscribeToDomainEventWithAggregateId
  *
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

  Context.prototype.subscribeToDomainEvents = function(domainEventHandlersObj) {
    var domainEventName, handlerFn;
    for (domainEventName in domainEventHandlersObj) {
      handlerFn = domainEventHandlersObj[domainEventName];
      this.subscribeToDomainEvent(domainEventName, handlerFn);
    }
    return this;
  };


  /**
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
   */

  Context.prototype.addDomainService = function(domainServiceName, domainServiceFn) {
    this._domainServices[domainServiceName] = (function(_this) {
      return function() {
        return domainServiceFn.apply(_this._di, arguments);
      };
    })(this);
    return this;
  };

  Context.prototype.addDomainServices = function(domainServiceObjs) {
    var domainServiceFn, domainServiceName;
    for (domainServiceName in domainServiceObjs) {
      domainServiceFn = domainServiceObjs[domainServiceName];
      this.addDomainService(domainServiceName, domainServiceFn);
    }
    return this;
  };


  /**
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
   */

  Context.prototype.addAdapter = function(adapterName, adapterClass) {
    this._adapterClasses[adapterName] = adapterClass;
    return this;
  };

  Context.prototype.addAdapters = function(adapterObj) {
    var adapterName, fn;
    for (adapterName in adapterObj) {
      fn = adapterObj[adapterName];
      this.addAdapter(adapterName, fn);
    }
    return this;
  };


  /**
  * @name addProjection
  *
  * @description
  * Add Projection that can subscribe to and handle DomainEvents
  *
  * @param {string} projectionName Name of the Projection
  * @param {Function} The Projection Class definition
  * - define `subscribeToDomainEvents` as Array of DomainEventName Strings
  * - define handle Funtions for DomainEvents by convention: "handleDomainEventName"
   */

  Context.prototype.addProjection = function(projectionName, ProjectionClass) {
    this._projectionClasses.push({
      name: projectionName,
      "class": ProjectionClass
    });
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


  /**
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
        _ref = eventric.defaults(_this._storeClasses, eventric.getStores());
        for (storeName in _ref) {
          store = _ref[storeName];
          stores.push({
            name: storeName,
            Class: store.Class,
            options: store.options
          });
        }
        return eventric.eachSeries(stores, function(store, next) {
          _this.log.debug("[" + _this.name + "] Initializing Store " + store.name);
          _this._storeInstances[store.name] = new store.Class;
          return _this._storeInstances[store.name].initialize(_this.name, store.options, function() {
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
        return eventric.eachSeries(_this._projectionClasses, function(projection, next) {
          var eventNames, projectionName;
          eventNames = null;
          projectionName = projection.name;
          _this.log.debug("[" + _this.name + "] Initializing Projection " + projectionName);
          return projectionService.initializeInstance(projection, {}, _this).then(function(projectionId) {
            _this.log.debug("[" + _this.name + "] Finished initializing Projection " + projectionName);
            return resolve(projectionId);
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
  *
  * @description Get a Projection Instance after initialize()
  *
  * @param {String} projectionName Name of the Projection
   */

  Context.prototype.getProjection = function(projectionId) {
    return projectionService.getInstance(projectionId);
  };


  /**
  * @name getAdapter
  *
  * @description Get a Adapter Instance after initialize()
  *
  * @param {String} adapterName Name of the Adapter
   */

  Context.prototype.getAdapter = function(adapterName) {
    return this._adapterInstances[adapterName];
  };


  /**
  * @name getDomainEvent
  *
  * @description Get a DomainEvent Class after initialize()
  *
  * @param {String} domainEventName Name of the DomainEvent
   */

  Context.prototype.getDomainEvent = function(domainEventName) {
    return this._domainEventClasses[domainEventName];
  };


  /**
  * @name getDomainService
  *
  * @description Get a DomainService after initialize()
  *
  * @param {String} domainServiceName Name of the DomainService
   */

  Context.prototype.getDomainService = function(domainServiceName) {
    return this._domainServices[domainServiceName];
  };


  /**
  * @name getDomainEventsStore
  *
  * @description Get the DomainEventsStore after initialization
   */

  Context.prototype.getDomainEventsStore = function() {
    var storeName;
    storeName = this.get('default domain events store');
    return this._storeInstances[storeName];
  };

  Context.prototype.saveDomainEvent = function() {
    var saveArguments;
    saveArguments = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var _ref;
        return (_ref = _this.getDomainEventsStore()).saveDomainEvent.apply(_ref, __slice.call(saveArguments).concat([function(err, events) {
          if (err) {
            return reject(err);
          }
          return resolve(events);
        }]));
      };
    })(this));
  };

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
  *
  * @description Get the EventBus after initialization
   */

  Context.prototype.getEventBus = function() {
    return this._eventBus;
  };


  /**
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
            return eventric.nextTick(function() {
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
            return eventric.nextTick(function() {
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

  Context.prototype.enableWaitingMode = function() {
    return this.set('waiting mode', true);
  };

  Context.prototype.disableWaitingMode = function() {
    return this.set('waiting mode', false);
  };

  Context.prototype.isWaitingModeEnabled = function() {
    return this.get('waiting mode');
  };

  return Context;

})(PubSub);

module.exports = Context;

  
});

require.register("eventric/src/domain_event", function(exports, require, module){
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

require.register("eventric/src/event_bus", function(exports, require, module){
  var EventBus, PubSub;

PubSub = require('./pub_sub');

EventBus = (function() {
  function EventBus() {
    this._pubSub = new PubSub();
  }

  EventBus.prototype.subscribeToDomainEventWithAggregateId = function(eventName, aggregateId, handlerFn, options) {
    if (options == null) {
      options = {};
    }
    return this.subscribeToDomainEvent("" + eventName + "/" + aggregateId, handlerFn, options);
  };

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

  EventBus.prototype.subscribeToAllDomainEvents = function(handlerFn) {
    return this._pubSub.subscribe('DomainEvent', handlerFn);
  };

  EventBus.prototype.publishDomainEvent = function(domainEvent, callback) {
    if (callback == null) {
      callback = function() {};
    }
    return this._publish('publish', domainEvent, callback);
  };

  EventBus.prototype.publishDomainEventAndWait = function(domainEvent, callback) {
    if (callback == null) {
      callback = function() {};
    }
    return this._publish('publishAsync', domainEvent, callback);
  };

  EventBus.prototype._publish = function(publishMethod, domainEvent, callback) {
    if (callback == null) {
      callback = function() {};
    }
    return this._pubSub[publishMethod]('DomainEvent', domainEvent, (function(_this) {
      return function() {
        return _this._pubSub[publishMethod](domainEvent.name, domainEvent, function() {
          if (domainEvent.aggregate && domainEvent.aggregate.id) {
            return _this._pubSub[publishMethod]("" + domainEvent.name + "/" + domainEvent.aggregate.id, domainEvent, callback);
          } else {
            return callback();
          }
        });
      };
    })(this));
  };

  return EventBus;

})();

module.exports = EventBus;

  
});

require.register("eventric/src/index", function(exports, require, module){
  var Eventric, promise,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __slice = [].slice;

promise = require('es6-promise');

if ((typeof module !== 'undefined') && (typeof process !== 'undefined')) {
  global.Promise = promise.Promise;
}

Eventric = (function() {
  function Eventric() {
    this._handleRemoteRPCRequest = __bind(this._handleRemoteRPCRequest, this);
    this._contexts = {};
    this._params = {};
    this._domainEventHandlers = {};
    this._domainEventHandlersAll = [];
    this._processManagerService = require('./process_manager');
    this._processManagerInstances = {};
    this._storeClasses = {};
    this._remoteEndpoints = [];
    this.log = require('./logger');
    this.addRemoteEndpoint('inmemory', (require('./remote_inmemory')).endpoint);
    this.addStore('inmemory', require('./store_inmemory'));
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


  /**
  *
  * @description Get a new context instance.
  *
  * @param {String} name Name of the context
   */

  Eventric.prototype.context = function(name) {
    var Context, context, err;
    if (!name) {
      err = 'Contexts must have a name';
      this.log.error(err);
      throw new Error(err);
    }
    Context = require('./context');
    context = new Context(name);
    this._delegateAllDomainEventsToGlobalHandlers(context);
    this._delegateAllDomainEventsToRemoteEndpoints(context);
    this._contexts[name] = context;
    return context;
  };

  Eventric.prototype.getContext = function(name) {
    return this._contexts[name];
  };

  Eventric.prototype.remote = function(contextName) {
    var Remote, err, remote;
    if (!contextName) {
      err = 'Missing context name';
      this.log.error(err);
      throw new Error(err);
    }
    Remote = require('./remote');
    remote = new Remote(contextName);
    return remote;
  };

  Eventric.prototype.addRemoteEndpoint = function(remoteName, remoteEndpoint) {
    this._remoteEndpoints.push(remoteEndpoint);
    return remoteEndpoint.setRPCHandler(this._handleRemoteRPCRequest);
  };

  Eventric.prototype._handleRemoteRPCRequest = function(request, callback) {
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
    return context[request.method].apply(context, request.params).then(function(result) {
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


  /**
  *
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


  /**
  *
  * @description Global Process Manager
  *
  * @param {String} processManagerName Name of the ProcessManager
  * @param {Object} processManagerObject Object containing `initializeWhen` and `class`
   */

  Eventric.prototype.addProcessManager = function(processManagerName, processManagerObj) {
    return this._processManagerService.add(processManagerName, processManagerObj, this);
  };

  Eventric.prototype.nextTick = function(next) {
    var nextTick, _ref;
    nextTick = (_ref = typeof process !== "undefined" && process !== null ? process.nextTick : void 0) != null ? _ref : setTimeout;
    return nextTick(function() {
      return next();
    });
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
          callback = function() {};
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

  return Eventric;

})();

module.exports = new Eventric;

  
});

require.register("eventric/src/logger", function(exports, require, module){
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

require.register("eventric/src/process_manager", function(exports, require, module){
  var ProcessManagerService;

ProcessManagerService = (function() {
  function ProcessManagerService() {
    this._processManagerInstances = {};
  }


  /**
  *
  * @description Process Manager
  *
  * @param {String} processManagerName Name of the ProcessManager
  * @param {Object} processManagerObject Object containing `initializeWhen` and `class`
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

require.register("eventric/src/projection", function(exports, require, module){
  var Projection, eventric,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

eventric = require('eventric');

Projection = (function() {
  function Projection() {
    this._applyDomainEventToProjection = __bind(this._applyDomainEventToProjection, this);
    this.log = eventric.log;
    this._handlerFunctions = {};
    this._projectionInstances = {};
  }

  Projection.prototype.initializeInstance = function(projectionObj, params, context) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var ProjectionClass, aggregateId, diFn, diName, projection, projectionId, projectionName, _ref;
        projectionName = projectionObj.name;
        ProjectionClass = projectionObj["class"];
        projection = new ProjectionClass;
        if (context._di) {
          _ref = context._di;
          for (diName in _ref) {
            diFn = _ref[diName];
            projection[diName] = diFn;
          }
        }
        projectionId = eventric.generateUid();
        aggregateId = null;
        projection.$subscribeHandlersWithAggregateId = function(_aggregateId) {
          return aggregateId = _aggregateId;
        };
        _this.log.debug("[" + context.name + "] Clearing Projections");
        return _this._clearProjectionStores(projection.stores, projectionName, context).then(function() {
          _this.log.debug("[" + context.name + "] Finished clearing Projections");
          return _this._injectStoresIntoProjection(projectionName, projection, context);
        }).then(function() {
          return _this._callInitializeOnProjection(projectionName, projection, params, context);
        }).then(function() {
          var eventName, eventNames, key, value;
          _this.log.debug("[" + context.name + "] Replaying DomainEvents against Projection " + projectionName);
          eventNames = [];
          for (key in projection) {
            value = projection[key];
            if ((key.indexOf('handle')) === 0 && (typeof value === 'function')) {
              eventName = key.replace(/^handle/, '');
              eventNames.push(eventName);
            }
          }
          return _this._applyDomainEventsFromStoreToProjection(projection, eventNames, aggregateId, context);
        }).then(function(eventNames) {
          _this.log.debug("[" + context.name + "] Finished Replaying DomainEvents against Projection " + projectionName);
          return _this._subscribeProjectionToDomainEvents(projectionId, projectionName, projection, eventNames, aggregateId, context);
        }).then(function() {
          _this._projectionInstances[projectionId] = projection;
          context.publish("projection:" + projectionName + ":initialized", {
            id: projectionId,
            projection: projection
          });
          return resolve(projectionId);
        })["catch"](function(err) {
          return reject(err);
        });
      };
    })(this));
  };

  Projection.prototype._callInitializeOnProjection = function(projectionName, projection, params, context) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        if (!projection.initialize) {
          _this.log.debug("[" + context.name + "] No initialize function on Projection " + projectionName + " given, skipping");
          return resolve(projection);
        }
        _this.log.debug("[" + context.name + "] Calling initialize on Projection " + projectionName);
        return projection.initialize(params, function() {
          _this.log.debug("[" + context.name + "] Finished initialize call on Projection " + projectionName);
          return resolve(projection);
        });
      };
    })(this));
  };

  Projection.prototype._injectStoresIntoProjection = function(projectionName, projection, context) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        if (!projection.stores) {
          return resolve();
        }
        if (projection["$store"] == null) {
          projection["$store"] = {};
        }
        return eventric.eachSeries(projection.stores, function(projectionStoreName, next) {
          _this.log.debug("[" + context.name + "] Injecting ProjectionStore " + projectionStoreName + " into Projection " + projectionName);
          return context.getProjectionStore(projectionStoreName, projectionName, function(err, projectionStore) {
            if (projectionStore) {
              projection["$store"][projectionStoreName] = projectionStore;
              _this.log.debug("[" + context.name + "] Finished Injecting ProjectionStore " + projectionStoreName + " into Projection " + projectionName);
              return next();
            }
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

  Projection.prototype._clearProjectionStores = function(projectionStores, projectionName, context) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        if (!projectionStores) {
          return resolve();
        }
        return eventric.eachSeries(projectionStores, function(projectionStoreName, next) {
          _this.log.debug("[" + context.name + "] Clearing ProjectionStore " + projectionStoreName + " for " + projectionName);
          return context.clearProjectionStore(projectionStoreName, projectionName, function() {
            _this.log.debug("[" + context.name + "] Finished clearing ProjectionStore " + projectionStoreName + " for " + projectionName);
            return next();
          });
        }, function(err) {
          return resolve();
        });
      };
    })(this));
  };

  Projection.prototype._applyDomainEventsFromStoreToProjection = function(projection, eventNames, aggregateId, context) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var findEvents;
        if (aggregateId) {
          findEvents = context.findDomainEventsByNameAndAggregateId(eventNames, aggregateId);
        } else {
          findEvents = context.findDomainEventsByName(eventNames);
        }
        return findEvents.then(function(domainEvents) {
          if (!domainEvents || domainEvents.length === 0) {
            return resolve(eventNames);
          }
          return eventric.eachSeries(domainEvents, function(event, next) {
            return _this._applyDomainEventToProjection(event, projection).then(function() {
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

  Projection.prototype._subscribeProjectionToDomainEvents = function(projectionId, projectionName, projection, eventNames, aggregateId, context) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var domainEventHandler, eventName, subscriberId, _base, _i, _len;
        domainEventHandler = function(domainEvent, done) {
          return _this._applyDomainEventToProjection(domainEvent, projection).then(function() {
            context.publish("projection:" + projectionName + ":changed", {
              id: projectionId,
              projection: projection
            });
            return done();
          });
        };
        for (_i = 0, _len = eventNames.length; _i < _len; _i++) {
          eventName = eventNames[_i];
          if (aggregateId) {
            subscriberId = context.subscribeToDomainEventWithAggregateId(eventName, aggregateId, domainEventHandler, {
              isAsync: true
            });
          } else {
            subscriberId = context.subscribeToDomainEvent(eventName, domainEventHandler, {
              isAsync: true
            });
          }
          if ((_base = _this._handlerFunctions)[projectionId] == null) {
            _base[projectionId] = [];
          }
          _this._handlerFunctions[projectionId].push(subscriberId);
        }
        return resolve();
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
          return projection["handle" + domainEvent.name](domainEvent, function() {
            return resolve();
          });
        } else {
          projection["handle" + domainEvent.name](domainEvent);
          return resolve();
        }
      };
    })(this));
  };

  Projection.prototype.getInstance = function(projectionId) {
    return this._projectionInstances[projectionId];
  };

  Projection.prototype.destroyInstance = function(projectionId, context) {
    var subscriberId, _i, _len, _ref;
    _ref = this._handlerFunctions[projectionId];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      subscriberId = _ref[_i];
      context.unsubscribeFromDomainEvent(subscriberId);
    }
    delete this._handlerFunctions[projectionId];
    return delete this._projectionInstances[projectionId];
  };

  return Projection;

})();

module.exports = new Projection;

  
});

require.register("eventric/src/pub_sub", function(exports, require, module){
  var PubSub,
  __slice = [].slice;

PubSub = (function() {
  function PubSub() {
    this._subscribers = [];
    this._subsrciberId = 0;
    this._nextTick = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return setTimeout.apply(null, args);
    };
  }

  PubSub.prototype.subscribe = function(eventName, subscriberFn) {
    var subscriber;
    subscriber = {
      eventName: eventName,
      subscriberFn: subscriberFn,
      subscriberId: this._getNextSubscriberId()
    };
    this._subscribers.push(subscriber);
    return subscriber.subscriberId;
  };

  PubSub.prototype.subscribeAsync = function(eventName, subscriberFn) {
    var subscriber;
    subscriber = {
      eventName: eventName,
      subscriberFn: subscriberFn,
      subscriberId: this._getNextSubscriberId(),
      isAsync: true
    };
    this._subscribers.push(subscriber);
    return subscriber.subscriberId;
  };

  PubSub.prototype.publish = function(eventName, payload, callback) {
    var executeNextHandler, subscribers;
    if (callback == null) {
      callback = function() {};
    }
    subscribers = this._getRelevantSubscribers(eventName);
    executeNextHandler = (function(_this) {
      return function() {
        if (subscribers.length === 0) {
          return callback();
        } else {
          subscribers.shift().subscriberFn(payload, function() {});
          return _this._nextTick(executeNextHandler, 0);
        }
      };
    })(this);
    return this._nextTick(executeNextHandler, 0);
  };

  PubSub.prototype.publishAsync = function(eventName, payload, callback) {
    var executeNextHandler, subscribers;
    if (callback == null) {
      callback = function() {};
    }
    subscribers = this._getRelevantSubscribers(eventName);
    executeNextHandler = (function(_this) {
      return function() {
        var subscriber;
        if (subscribers.length === 0) {
          return callback();
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
    })(this);
    return this._nextTick(executeNextHandler, 0);
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

  PubSub.prototype.unsubscribe = function(subscriberId) {
    return this._subscribers = this._subscribers.filter(function(x) {
      return x.subscriberId !== subscriberId;
    });
  };

  PubSub.prototype._getNextSubscriberId = function() {
    return this._subsrciberId++;
  };

  return PubSub;

})();

module.exports = PubSub;

  
});

require.register("eventric/src/remote", function(exports, require, module){
  var PubSub, Remote, eventric, projectionService,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

eventric = require('eventric');

PubSub = require('./pub_sub');

projectionService = require('./projection');

Remote = (function(_super) {
  __extends(Remote, _super);

  function Remote(_contextName) {
    this._contextName = _contextName;
    Remote.__super__.constructor.apply(this, arguments);
    this.name = this._contextName;
    this._params = {};
    this._clients = {};
    this._projectionClasses = {};
    this._projectionInstances = {};
    this._handlerFunctions = {};
    this.addClient('inmemory', (require('./remote_inmemory')).client);
    this.set('default client', 'inmemory');
  }

  Remote.prototype.set = function(key, value) {
    this._params[key] = value;
    return this;
  };

  Remote.prototype.get = function(key) {
    return this._params[key];
  };

  Remote.prototype.command = function() {
    return this._rpc('command', arguments);
  };

  Remote.prototype.query = function() {
    return this._rpc('query', arguments);
  };

  Remote.prototype.findAllDomainEvents = function() {
    return this._rpc('findAllDomainEvents', arguments);
  };

  Remote.prototype.findDomainEventsByName = function() {
    return this._rpc('findDomainEventsByName', arguments);
  };

  Remote.prototype.findDomainEventsByAggregateId = function() {
    return this._rpc('findDomainEventsByAggregateId', arguments);
  };

  Remote.prototype.findDomainEventsByAggregateName = function() {
    return this._rpc('findDomainEventsByAggregateName', arguments);
  };

  Remote.prototype.findDomainEventsByNameAndAggregateId = function() {
    return this._rpc('findDomainEventsByNameAndAggregateId', arguments);
  };

  Remote.prototype.subscribeToAllDomainEvents = function(handlerFn, options) {
    var client, clientName;
    if (options == null) {
      options = {};
    }
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.subscribe(this._contextName, handlerFn);
  };

  Remote.prototype.subscribeToDomainEvent = function(domainEventName, handlerFn, options) {
    var client, clientName;
    if (options == null) {
      options = {};
    }
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.subscribe(this._contextName, domainEventName, handlerFn);
  };

  Remote.prototype.subscribeToDomainEventWithAggregateId = function(domainEventName, aggregateId, handlerFn, options) {
    var client, clientName;
    if (options == null) {
      options = {};
    }
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

  Remote.prototype._rpc = function(method, params) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var client, clientName;
        clientName = _this.get('default client');
        client = _this.getClient(clientName);
        return client.rpc({
          contextName: _this._contextName,
          method: method,
          params: Array.prototype.slice.call(params)
        }, function(err, result) {
          if (err) {
            return reject(err);
          } else {
            return resolve(result);
          }
        });
      };
    })(this));
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

  Remote.prototype.initializeProjectionInstance = function(projectionName, params) {
    var err;
    if (!this._projectionClasses[projectionName]) {
      err = "Given projection " + projectionName + " not registered on remote";
      eventric.log.error(err);
      err = new Error(err);
      return reject(err);
    }
    return projectionService.initializeInstance({
      name: projectionName,
      "class": this._projectionClasses[projectionName]
    }, params, this);
  };

  Remote.prototype.getProjectionInstance = function(projectionId) {
    return projectionService.getInstance(projectionId);
  };

  Remote.prototype.destroyProjectionInstance = function(projectionId) {
    return projectionService.destroyInstance(projectionId, this);
  };

  return Remote;

})(PubSub);

module.exports = Remote;

  
});

require.register("eventric/src/remote_inmemory", function(exports, require, module){
  var InMemoryRemoteClient, InMemoryRemoteEndpoint, PubSub, customRemoteBridge, getFullEventName, pubSub,
  __slice = [].slice;

PubSub = require('./pub_sub');

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

  InMemoryRemoteEndpoint.prototype.setRPCHandler = function(_handleRPCRequest) {
    this._handleRPCRequest = _handleRPCRequest;
  };

  InMemoryRemoteEndpoint.prototype.publish = function() {
    var aggregateId, context, domainEventName, fullEventName, payload, _arg, _i;
    context = arguments[0], _arg = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), payload = arguments[_i++];
    domainEventName = _arg[0], aggregateId = _arg[1];
    fullEventName = getFullEventName(context, domainEventName, aggregateId);
    return pubSub.publish(fullEventName, payload, function() {});
  };

  return InMemoryRemoteEndpoint;

})();

module.exports.endpoint = new InMemoryRemoteEndpoint;

InMemoryRemoteClient = (function() {
  function InMemoryRemoteClient() {}

  InMemoryRemoteClient.prototype.rpc = function(rpcRequest, callback) {
    if (!customRemoteBridge) {
      throw new Error('No Remote Endpoint available for in memory client');
    }
    return customRemoteBridge(rpcRequest).then(function(result) {
      return callback(null, result);
    })["catch"](function(error) {
      return callback(error);
    });
  };

  InMemoryRemoteClient.prototype.subscribe = function() {
    var aggregateId, context, domainEventName, fullEventName, handlerFn, _arg, _i;
    context = arguments[0], _arg = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), handlerFn = arguments[_i++];
    domainEventName = _arg[0], aggregateId = _arg[1];
    fullEventName = getFullEventName(context, domainEventName, aggregateId);
    return pubSub.subscribe(fullEventName, handlerFn);
  };

  InMemoryRemoteClient.prototype.unsubscribe = function(subscriberId) {
    return pubSub.unsubscribe(subscriberId);
  };

  return InMemoryRemoteClient;

})();

module.exports.client = new InMemoryRemoteClient;

getFullEventName = function(context, domainEventName, aggregateId) {
  var fullEventName;
  fullEventName = context;
  if (domainEventName) {
    fullEventName += "/" + domainEventName;
  }
  if (aggregateId) {
    fullEventName += "/" + aggregateId;
  }
  return fullEventName;
};

  
});

require.register("eventric/src/repository", function(exports, require, module){
  var Aggregate, Repository, eventric,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

eventric = require('eventric');

Aggregate = require('./aggregate');

Repository = (function() {
  function Repository(params) {
    this.save = __bind(this.save, this);
    this.create = __bind(this.create, this);
    this.findById = __bind(this.findById, this);
    this._aggregateName = params.aggregateName;
    this._AggregateRoot = params.AggregateRoot;
    this._context = params.context;
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
            eventric.log.error(err);
            callback(err, null);
            reject(err);
            return;
          }
          aggregate = new Aggregate(_this._context, _this._aggregateName, _this._AggregateRoot);
          aggregate.applyDomainEvents(domainEvents);
          aggregate.id = aggregateId;
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

  Repository.prototype.create = function() {
    var callback, params;
    params = arguments;
    if (typeof params[params.length - 1] === 'function') {
      callback = params.pop();
    }
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var aggregate;
        aggregate = new Aggregate(_this._context, _this._aggregateName, _this._AggregateRoot);
        return aggregate.create.apply(aggregate, params).then(function(aggregate) {
          var commandId, _base, _ref;
          commandId = (_ref = _this._command.id) != null ? _ref : 'nocommand';
          if ((_base = _this._aggregateInstances)[commandId] == null) {
            _base[commandId] = {};
          }
          _this._aggregateInstances[commandId][aggregate.id] = aggregate;
          if (typeof callback === "function") {
            callback(null, aggregate.id);
          }
          return resolve(aggregate.id);
        });
      };
    })(this));
  };

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
          eventric.log.error(err);
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
          eventric.log.debug(err, _this._command);
          err = new Error(err);
          if (typeof callback === "function") {
            callback(err, null);
          }
          reject(err);
          return;
        }
        eventric.log.debug("Going to Save and Publish " + domainEvents.length + " DomainEvents from Aggregate " + _this._aggregateName);
        return eventric.eachSeries(domainEvents, function(domainEvent, next) {
          domainEvent.command = _this._command;
          return _this._store.saveDomainEvent(domainEvent, function() {
            eventric.log.debug("Saved DomainEvent", domainEvent);
            return next(null);
          });
        }, function(err) {
          var domainEvent, _i, _len;
          if (err) {
            callback(err, null);
            return reject(err);
          } else {
            if (!_this._context.isWaitingModeEnabled()) {
              for (_i = 0, _len = domainEvents.length; _i < _len; _i++) {
                domainEvent = domainEvents[_i];
                eventric.log.debug("Publishing DomainEvent", domainEvent);
                _this._context.getEventBus().publishDomainEvent(domainEvent, function() {});
              }
              resolve(aggregate.id);
              return callback(null, aggregate.id);
            } else {
              return eventric.eachSeries(domainEvents, function(domainEvent, next) {
                eventric.log.debug("Publishing DomainEvent in waiting mode", domainEvent);
                return _this._context.getEventBus().publishDomainEventAndWait(domainEvent, next);
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
          }
        });
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

require.register("eventric/src/store_inmemory", function(exports, require, module){
  var InMemoryStore, STORE_SUPPORTS,
  __slice = [].slice;

STORE_SUPPORTS = ['domain_events', 'projections'];

InMemoryStore = (function() {
  function InMemoryStore() {}

  InMemoryStore.prototype._domainEvents = {};

  InMemoryStore.prototype._projections = {};

  InMemoryStore.prototype.initialize = function() {
    var callback, options, _arg, _contextName, _i;
    _contextName = arguments[0], _arg = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), callback = arguments[_i++];
    this._contextName = _contextName;
    options = _arg[0];
    this._domainEventsCollectionName = "" + this._contextName + ".DomainEvents";
    this._projectionCollectionName = "" + this._contextName + ".Projections";
    this._domainEvents[this._domainEventsCollectionName] = [];
    return callback();
  };

  InMemoryStore.prototype.saveDomainEvent = function(domainEvent, callback) {
    this._domainEvents[this._domainEventsCollectionName].push(domainEvent);
    return callback(null, domainEvent);
  };

  InMemoryStore.prototype.findAllDomainEvents = function(callback) {
    return callback(null, this._domainEvents[this._domainEventsCollectionName]);
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

  InMemoryStore.prototype.getProjectionStore = function(projectionName, callback) {
    var _base, _base1, _name;
    if ((_base = this._projections)[_name = this._projectionCollectionName] == null) {
      _base[_name] = {};
    }
    if ((_base1 = this._projections[this._projectionCollectionName])[projectionName] == null) {
      _base1[projectionName] = {};
    }
    return callback(null, this._projections[this._projectionCollectionName][projectionName]);
  };

  InMemoryStore.prototype.clearProjectionStore = function(projectionName, callback) {
    var _base, _base1, _name;
    if ((_base = this._projections)[_name = this._projectionCollectionName] == null) {
      _base[_name] = {};
    }
    if ((_base1 = this._projections[this._projectionCollectionName])[projectionName] == null) {
      _base1[projectionName] = {};
    }
    delete this._projections[this._projectionCollectionName][projectionName];
    return callback(null, null);
  };

  InMemoryStore.prototype.checkSupport = function(check) {
    return (STORE_SUPPORTS.indexOf(check)) > -1;
  };

  return InMemoryStore;

})();

module.exports = InMemoryStore;

  
});
