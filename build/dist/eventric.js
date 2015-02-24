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
    this._delegateAllDomainEventsToRemoteEndpoints(context);
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

require.register("eventric/index", function(exports, require, module){
  require('es6-promise').polyfill();

module.exports = new (require('./eventric'));

  
});

require.register("es6-promise", function(exports, require, module){
  /*!
 * @overview es6-promise - a tiny implementation of Promises/A+.
 * @copyright Copyright (c) 2014 Yehuda Katz, Tom Dale, Stefan Penner and contributors (Conversion to ES6 API by Jake Archibald)
 * @license   Licensed under MIT license
 *            See https://raw.githubusercontent.com/jakearchibald/es6-promise/master/LICENSE
 * @version   2.0.1
 */

(function() {
    "use strict";

    function $$utils$$objectOrFunction(x) {
      return typeof x === 'function' || (typeof x === 'object' && x !== null);
    }

    function $$utils$$isFunction(x) {
      return typeof x === 'function';
    }

    function $$utils$$isMaybeThenable(x) {
      return typeof x === 'object' && x !== null;
    }

    var $$utils$$_isArray;

    if (!Array.isArray) {
      $$utils$$_isArray = function (x) {
        return Object.prototype.toString.call(x) === '[object Array]';
      };
    } else {
      $$utils$$_isArray = Array.isArray;
    }

    var $$utils$$isArray = $$utils$$_isArray;
    var $$utils$$now = Date.now || function() { return new Date().getTime(); };
    function $$utils$$F() { }

    var $$utils$$o_create = (Object.create || function (o) {
      if (arguments.length > 1) {
        throw new Error('Second argument not supported');
      }
      if (typeof o !== 'object') {
        throw new TypeError('Argument must be an object');
      }
      $$utils$$F.prototype = o;
      return new $$utils$$F();
    });

    var $$asap$$len = 0;

    var $$asap$$default = function asap(callback, arg) {
      $$asap$$queue[$$asap$$len] = callback;
      $$asap$$queue[$$asap$$len + 1] = arg;
      $$asap$$len += 2;
      if ($$asap$$len === 2) {
        // If len is 1, that means that we need to schedule an async flush.
        // If additional callbacks are queued before the queue is flushed, they
        // will be processed by this flush that we are scheduling.
        $$asap$$scheduleFlush();
      }
    };

    var $$asap$$browserGlobal = (typeof window !== 'undefined') ? window : {};
    var $$asap$$BrowserMutationObserver = $$asap$$browserGlobal.MutationObserver || $$asap$$browserGlobal.WebKitMutationObserver;

    // test for web worker but not in IE10
    var $$asap$$isWorker = typeof Uint8ClampedArray !== 'undefined' &&
      typeof importScripts !== 'undefined' &&
      typeof MessageChannel !== 'undefined';

    // node
    function $$asap$$useNextTick() {
      return function() {
        process.nextTick($$asap$$flush);
      };
    }

    function $$asap$$useMutationObserver() {
      var iterations = 0;
      var observer = new $$asap$$BrowserMutationObserver($$asap$$flush);
      var node = document.createTextNode('');
      observer.observe(node, { characterData: true });

      return function() {
        node.data = (iterations = ++iterations % 2);
      };
    }

    // web worker
    function $$asap$$useMessageChannel() {
      var channel = new MessageChannel();
      channel.port1.onmessage = $$asap$$flush;
      return function () {
        channel.port2.postMessage(0);
      };
    }

    function $$asap$$useSetTimeout() {
      return function() {
        setTimeout($$asap$$flush, 1);
      };
    }

    var $$asap$$queue = new Array(1000);

    function $$asap$$flush() {
      for (var i = 0; i < $$asap$$len; i+=2) {
        var callback = $$asap$$queue[i];
        var arg = $$asap$$queue[i+1];

        callback(arg);

        $$asap$$queue[i] = undefined;
        $$asap$$queue[i+1] = undefined;
      }

      $$asap$$len = 0;
    }

    var $$asap$$scheduleFlush;

    // Decide what async method to use to triggering processing of queued callbacks:
    if (typeof process !== 'undefined' && {}.toString.call(process) === '[object process]') {
      $$asap$$scheduleFlush = $$asap$$useNextTick();
    } else if ($$asap$$BrowserMutationObserver) {
      $$asap$$scheduleFlush = $$asap$$useMutationObserver();
    } else if ($$asap$$isWorker) {
      $$asap$$scheduleFlush = $$asap$$useMessageChannel();
    } else {
      $$asap$$scheduleFlush = $$asap$$useSetTimeout();
    }

    function $$$internal$$noop() {}
    var $$$internal$$PENDING   = void 0;
    var $$$internal$$FULFILLED = 1;
    var $$$internal$$REJECTED  = 2;
    var $$$internal$$GET_THEN_ERROR = new $$$internal$$ErrorObject();

    function $$$internal$$selfFullfillment() {
      return new TypeError("You cannot resolve a promise with itself");
    }

    function $$$internal$$cannotReturnOwn() {
      return new TypeError('A promises callback cannot return that same promise.')
    }

    function $$$internal$$getThen(promise) {
      try {
        return promise.then;
      } catch(error) {
        $$$internal$$GET_THEN_ERROR.error = error;
        return $$$internal$$GET_THEN_ERROR;
      }
    }

    function $$$internal$$tryThen(then, value, fulfillmentHandler, rejectionHandler) {
      try {
        then.call(value, fulfillmentHandler, rejectionHandler);
      } catch(e) {
        return e;
      }
    }

    function $$$internal$$handleForeignThenable(promise, thenable, then) {
       $$asap$$default(function(promise) {
        var sealed = false;
        var error = $$$internal$$tryThen(then, thenable, function(value) {
          if (sealed) { return; }
          sealed = true;
          if (thenable !== value) {
            $$$internal$$resolve(promise, value);
          } else {
            $$$internal$$fulfill(promise, value);
          }
        }, function(reason) {
          if (sealed) { return; }
          sealed = true;

          $$$internal$$reject(promise, reason);
        }, 'Settle: ' + (promise._label || ' unknown promise'));

        if (!sealed && error) {
          sealed = true;
          $$$internal$$reject(promise, error);
        }
      }, promise);
    }

    function $$$internal$$handleOwnThenable(promise, thenable) {
      if (thenable._state === $$$internal$$FULFILLED) {
        $$$internal$$fulfill(promise, thenable._result);
      } else if (promise._state === $$$internal$$REJECTED) {
        $$$internal$$reject(promise, thenable._result);
      } else {
        $$$internal$$subscribe(thenable, undefined, function(value) {
          $$$internal$$resolve(promise, value);
        }, function(reason) {
          $$$internal$$reject(promise, reason);
        });
      }
    }

    function $$$internal$$handleMaybeThenable(promise, maybeThenable) {
      if (maybeThenable.constructor === promise.constructor) {
        $$$internal$$handleOwnThenable(promise, maybeThenable);
      } else {
        var then = $$$internal$$getThen(maybeThenable);

        if (then === $$$internal$$GET_THEN_ERROR) {
          $$$internal$$reject(promise, $$$internal$$GET_THEN_ERROR.error);
        } else if (then === undefined) {
          $$$internal$$fulfill(promise, maybeThenable);
        } else if ($$utils$$isFunction(then)) {
          $$$internal$$handleForeignThenable(promise, maybeThenable, then);
        } else {
          $$$internal$$fulfill(promise, maybeThenable);
        }
      }
    }

    function $$$internal$$resolve(promise, value) {
      if (promise === value) {
        $$$internal$$reject(promise, $$$internal$$selfFullfillment());
      } else if ($$utils$$objectOrFunction(value)) {
        $$$internal$$handleMaybeThenable(promise, value);
      } else {
        $$$internal$$fulfill(promise, value);
      }
    }

    function $$$internal$$publishRejection(promise) {
      if (promise._onerror) {
        promise._onerror(promise._result);
      }

      $$$internal$$publish(promise);
    }

    function $$$internal$$fulfill(promise, value) {
      if (promise._state !== $$$internal$$PENDING) { return; }

      promise._result = value;
      promise._state = $$$internal$$FULFILLED;

      if (promise._subscribers.length === 0) {
      } else {
        $$asap$$default($$$internal$$publish, promise);
      }
    }

    function $$$internal$$reject(promise, reason) {
      if (promise._state !== $$$internal$$PENDING) { return; }
      promise._state = $$$internal$$REJECTED;
      promise._result = reason;

      $$asap$$default($$$internal$$publishRejection, promise);
    }

    function $$$internal$$subscribe(parent, child, onFulfillment, onRejection) {
      var subscribers = parent._subscribers;
      var length = subscribers.length;

      parent._onerror = null;

      subscribers[length] = child;
      subscribers[length + $$$internal$$FULFILLED] = onFulfillment;
      subscribers[length + $$$internal$$REJECTED]  = onRejection;

      if (length === 0 && parent._state) {
        $$asap$$default($$$internal$$publish, parent);
      }
    }

    function $$$internal$$publish(promise) {
      var subscribers = promise._subscribers;
      var settled = promise._state;

      if (subscribers.length === 0) { return; }

      var child, callback, detail = promise._result;

      for (var i = 0; i < subscribers.length; i += 3) {
        child = subscribers[i];
        callback = subscribers[i + settled];

        if (child) {
          $$$internal$$invokeCallback(settled, child, callback, detail);
        } else {
          callback(detail);
        }
      }

      promise._subscribers.length = 0;
    }

    function $$$internal$$ErrorObject() {
      this.error = null;
    }

    var $$$internal$$TRY_CATCH_ERROR = new $$$internal$$ErrorObject();

    function $$$internal$$tryCatch(callback, detail) {
      try {
        return callback(detail);
      } catch(e) {
        $$$internal$$TRY_CATCH_ERROR.error = e;
        return $$$internal$$TRY_CATCH_ERROR;
      }
    }

    function $$$internal$$invokeCallback(settled, promise, callback, detail) {
      var hasCallback = $$utils$$isFunction(callback),
          value, error, succeeded, failed;

      if (hasCallback) {
        value = $$$internal$$tryCatch(callback, detail);

        if (value === $$$internal$$TRY_CATCH_ERROR) {
          failed = true;
          error = value.error;
          value = null;
        } else {
          succeeded = true;
        }

        if (promise === value) {
          $$$internal$$reject(promise, $$$internal$$cannotReturnOwn());
          return;
        }

      } else {
        value = detail;
        succeeded = true;
      }

      if (promise._state !== $$$internal$$PENDING) {
        // noop
      } else if (hasCallback && succeeded) {
        $$$internal$$resolve(promise, value);
      } else if (failed) {
        $$$internal$$reject(promise, error);
      } else if (settled === $$$internal$$FULFILLED) {
        $$$internal$$fulfill(promise, value);
      } else if (settled === $$$internal$$REJECTED) {
        $$$internal$$reject(promise, value);
      }
    }

    function $$$internal$$initializePromise(promise, resolver) {
      try {
        resolver(function resolvePromise(value){
          $$$internal$$resolve(promise, value);
        }, function rejectPromise(reason) {
          $$$internal$$reject(promise, reason);
        });
      } catch(e) {
        $$$internal$$reject(promise, e);
      }
    }

    function $$$enumerator$$makeSettledResult(state, position, value) {
      if (state === $$$internal$$FULFILLED) {
        return {
          state: 'fulfilled',
          value: value
        };
      } else {
        return {
          state: 'rejected',
          reason: value
        };
      }
    }

    function $$$enumerator$$Enumerator(Constructor, input, abortOnReject, label) {
      this._instanceConstructor = Constructor;
      this.promise = new Constructor($$$internal$$noop, label);
      this._abortOnReject = abortOnReject;

      if (this._validateInput(input)) {
        this._input     = input;
        this.length     = input.length;
        this._remaining = input.length;

        this._init();

        if (this.length === 0) {
          $$$internal$$fulfill(this.promise, this._result);
        } else {
          this.length = this.length || 0;
          this._enumerate();
          if (this._remaining === 0) {
            $$$internal$$fulfill(this.promise, this._result);
          }
        }
      } else {
        $$$internal$$reject(this.promise, this._validationError());
      }
    }

    $$$enumerator$$Enumerator.prototype._validateInput = function(input) {
      return $$utils$$isArray(input);
    };

    $$$enumerator$$Enumerator.prototype._validationError = function() {
      return new Error('Array Methods must be provided an Array');
    };

    $$$enumerator$$Enumerator.prototype._init = function() {
      this._result = new Array(this.length);
    };

    var $$$enumerator$$default = $$$enumerator$$Enumerator;

    $$$enumerator$$Enumerator.prototype._enumerate = function() {
      var length  = this.length;
      var promise = this.promise;
      var input   = this._input;

      for (var i = 0; promise._state === $$$internal$$PENDING && i < length; i++) {
        this._eachEntry(input[i], i);
      }
    };

    $$$enumerator$$Enumerator.prototype._eachEntry = function(entry, i) {
      var c = this._instanceConstructor;
      if ($$utils$$isMaybeThenable(entry)) {
        if (entry.constructor === c && entry._state !== $$$internal$$PENDING) {
          entry._onerror = null;
          this._settledAt(entry._state, i, entry._result);
        } else {
          this._willSettleAt(c.resolve(entry), i);
        }
      } else {
        this._remaining--;
        this._result[i] = this._makeResult($$$internal$$FULFILLED, i, entry);
      }
    };

    $$$enumerator$$Enumerator.prototype._settledAt = function(state, i, value) {
      var promise = this.promise;

      if (promise._state === $$$internal$$PENDING) {
        this._remaining--;

        if (this._abortOnReject && state === $$$internal$$REJECTED) {
          $$$internal$$reject(promise, value);
        } else {
          this._result[i] = this._makeResult(state, i, value);
        }
      }

      if (this._remaining === 0) {
        $$$internal$$fulfill(promise, this._result);
      }
    };

    $$$enumerator$$Enumerator.prototype._makeResult = function(state, i, value) {
      return value;
    };

    $$$enumerator$$Enumerator.prototype._willSettleAt = function(promise, i) {
      var enumerator = this;

      $$$internal$$subscribe(promise, undefined, function(value) {
        enumerator._settledAt($$$internal$$FULFILLED, i, value);
      }, function(reason) {
        enumerator._settledAt($$$internal$$REJECTED, i, reason);
      });
    };

    var $$promise$all$$default = function all(entries, label) {
      return new $$$enumerator$$default(this, entries, true /* abort on reject */, label).promise;
    };

    var $$promise$race$$default = function race(entries, label) {
      /*jshint validthis:true */
      var Constructor = this;

      var promise = new Constructor($$$internal$$noop, label);

      if (!$$utils$$isArray(entries)) {
        $$$internal$$reject(promise, new TypeError('You must pass an array to race.'));
        return promise;
      }

      var length = entries.length;

      function onFulfillment(value) {
        $$$internal$$resolve(promise, value);
      }

      function onRejection(reason) {
        $$$internal$$reject(promise, reason);
      }

      for (var i = 0; promise._state === $$$internal$$PENDING && i < length; i++) {
        $$$internal$$subscribe(Constructor.resolve(entries[i]), undefined, onFulfillment, onRejection);
      }

      return promise;
    };

    var $$promise$resolve$$default = function resolve(object, label) {
      /*jshint validthis:true */
      var Constructor = this;

      if (object && typeof object === 'object' && object.constructor === Constructor) {
        return object;
      }

      var promise = new Constructor($$$internal$$noop, label);
      $$$internal$$resolve(promise, object);
      return promise;
    };

    var $$promise$reject$$default = function reject(reason, label) {
      /*jshint validthis:true */
      var Constructor = this;
      var promise = new Constructor($$$internal$$noop, label);
      $$$internal$$reject(promise, reason);
      return promise;
    };

    var $$es6$promise$promise$$counter = 0;

    function $$es6$promise$promise$$needsResolver() {
      throw new TypeError('You must pass a resolver function as the first argument to the promise constructor');
    }

    function $$es6$promise$promise$$needsNew() {
      throw new TypeError("Failed to construct 'Promise': Please use the 'new' operator, this object constructor cannot be called as a function.");
    }

    var $$es6$promise$promise$$default = $$es6$promise$promise$$Promise;

    /**
      Promise objects represent the eventual result of an asynchronous operation. The
      primary way of interacting with a promise is through its `then` method, which
      registers callbacks to receive either a promise’s eventual value or the reason
      why the promise cannot be fulfilled.

      Terminology
      -----------

      - `promise` is an object or function with a `then` method whose behavior conforms to this specification.
      - `thenable` is an object or function that defines a `then` method.
      - `value` is any legal JavaScript value (including undefined, a thenable, or a promise).
      - `exception` is a value that is thrown using the throw statement.
      - `reason` is a value that indicates why a promise was rejected.
      - `settled` the final resting state of a promise, fulfilled or rejected.

      A promise can be in one of three states: pending, fulfilled, or rejected.

      Promises that are fulfilled have a fulfillment value and are in the fulfilled
      state.  Promises that are rejected have a rejection reason and are in the
      rejected state.  A fulfillment value is never a thenable.

      Promises can also be said to *resolve* a value.  If this value is also a
      promise, then the original promise's settled state will match the value's
      settled state.  So a promise that *resolves* a promise that rejects will
      itself reject, and a promise that *resolves* a promise that fulfills will
      itself fulfill.


      Basic Usage:
      ------------

      ```js
      var promise = new Promise(function(resolve, reject) {
        // on success
        resolve(value);

        // on failure
        reject(reason);
      });

      promise.then(function(value) {
        // on fulfillment
      }, function(reason) {
        // on rejection
      });
      ```

      Advanced Usage:
      ---------------

      Promises shine when abstracting away asynchronous interactions such as
      `XMLHttpRequest`s.

      ```js
      function getJSON(url) {
        return new Promise(function(resolve, reject){
          var xhr = new XMLHttpRequest();

          xhr.open('GET', url);
          xhr.onreadystatechange = handler;
          xhr.responseType = 'json';
          xhr.setRequestHeader('Accept', 'application/json');
          xhr.send();

          function handler() {
            if (this.readyState === this.DONE) {
              if (this.status === 200) {
                resolve(this.response);
              } else {
                reject(new Error('getJSON: `' + url + '` failed with status: [' + this.status + ']'));
              }
            }
          };
        });
      }

      getJSON('/posts.json').then(function(json) {
        // on fulfillment
      }, function(reason) {
        // on rejection
      });
      ```

      Unlike callbacks, promises are great composable primitives.

      ```js
      Promise.all([
        getJSON('/posts'),
        getJSON('/comments')
      ]).then(function(values){
        values[0] // => postsJSON
        values[1] // => commentsJSON

        return values;
      });
      ```

      @class Promise
      @param {function} resolver
      Useful for tooling.
      @constructor
    */
    function $$es6$promise$promise$$Promise(resolver) {
      this._id = $$es6$promise$promise$$counter++;
      this._state = undefined;
      this._result = undefined;
      this._subscribers = [];

      if ($$$internal$$noop !== resolver) {
        if (!$$utils$$isFunction(resolver)) {
          $$es6$promise$promise$$needsResolver();
        }

        if (!(this instanceof $$es6$promise$promise$$Promise)) {
          $$es6$promise$promise$$needsNew();
        }

        $$$internal$$initializePromise(this, resolver);
      }
    }

    $$es6$promise$promise$$Promise.all = $$promise$all$$default;
    $$es6$promise$promise$$Promise.race = $$promise$race$$default;
    $$es6$promise$promise$$Promise.resolve = $$promise$resolve$$default;
    $$es6$promise$promise$$Promise.reject = $$promise$reject$$default;

    $$es6$promise$promise$$Promise.prototype = {
      constructor: $$es6$promise$promise$$Promise,

    /**
      The primary way of interacting with a promise is through its `then` method,
      which registers callbacks to receive either a promise's eventual value or the
      reason why the promise cannot be fulfilled.

      ```js
      findUser().then(function(user){
        // user is available
      }, function(reason){
        // user is unavailable, and you are given the reason why
      });
      ```

      Chaining
      --------

      The return value of `then` is itself a promise.  This second, 'downstream'
      promise is resolved with the return value of the first promise's fulfillment
      or rejection handler, or rejected if the handler throws an exception.

      ```js
      findUser().then(function (user) {
        return user.name;
      }, function (reason) {
        return 'default name';
      }).then(function (userName) {
        // If `findUser` fulfilled, `userName` will be the user's name, otherwise it
        // will be `'default name'`
      });

      findUser().then(function (user) {
        throw new Error('Found user, but still unhappy');
      }, function (reason) {
        throw new Error('`findUser` rejected and we're unhappy');
      }).then(function (value) {
        // never reached
      }, function (reason) {
        // if `findUser` fulfilled, `reason` will be 'Found user, but still unhappy'.
        // If `findUser` rejected, `reason` will be '`findUser` rejected and we're unhappy'.
      });
      ```
      If the downstream promise does not specify a rejection handler, rejection reasons will be propagated further downstream.

      ```js
      findUser().then(function (user) {
        throw new PedagogicalException('Upstream error');
      }).then(function (value) {
        // never reached
      }).then(function (value) {
        // never reached
      }, function (reason) {
        // The `PedgagocialException` is propagated all the way down to here
      });
      ```

      Assimilation
      ------------

      Sometimes the value you want to propagate to a downstream promise can only be
      retrieved asynchronously. This can be achieved by returning a promise in the
      fulfillment or rejection handler. The downstream promise will then be pending
      until the returned promise is settled. This is called *assimilation*.

      ```js
      findUser().then(function (user) {
        return findCommentsByAuthor(user);
      }).then(function (comments) {
        // The user's comments are now available
      });
      ```

      If the assimliated promise rejects, then the downstream promise will also reject.

      ```js
      findUser().then(function (user) {
        return findCommentsByAuthor(user);
      }).then(function (comments) {
        // If `findCommentsByAuthor` fulfills, we'll have the value here
      }, function (reason) {
        // If `findCommentsByAuthor` rejects, we'll have the reason here
      });
      ```

      Simple Example
      --------------

      Synchronous Example

      ```javascript
      var result;

      try {
        result = findResult();
        // success
      } catch(reason) {
        // failure
      }
      ```

      Errback Example

      ```js
      findResult(function(result, err){
        if (err) {
          // failure
        } else {
          // success
        }
      });
      ```

      Promise Example;

      ```javascript
      findResult().then(function(result){
        // success
      }, function(reason){
        // failure
      });
      ```

      Advanced Example
      --------------

      Synchronous Example

      ```javascript
      var author, books;

      try {
        author = findAuthor();
        books  = findBooksByAuthor(author);
        // success
      } catch(reason) {
        // failure
      }
      ```

      Errback Example

      ```js

      function foundBooks(books) {

      }

      function failure(reason) {

      }

      findAuthor(function(author, err){
        if (err) {
          failure(err);
          // failure
        } else {
          try {
            findBoooksByAuthor(author, function(books, err) {
              if (err) {
                failure(err);
              } else {
                try {
                  foundBooks(books);
                } catch(reason) {
                  failure(reason);
                }
              }
            });
          } catch(error) {
            failure(err);
          }
          // success
        }
      });
      ```

      Promise Example;

      ```javascript
      findAuthor().
        then(findBooksByAuthor).
        then(function(books){
          // found books
      }).catch(function(reason){
        // something went wrong
      });
      ```

      @method then
      @param {Function} onFulfilled
      @param {Function} onRejected
      Useful for tooling.
      @return {Promise}
    */
      then: function(onFulfillment, onRejection) {
        var parent = this;
        var state = parent._state;

        if (state === $$$internal$$FULFILLED && !onFulfillment || state === $$$internal$$REJECTED && !onRejection) {
          return this;
        }

        var child = new this.constructor($$$internal$$noop);
        var result = parent._result;

        if (state) {
          var callback = arguments[state - 1];
          $$asap$$default(function(){
            $$$internal$$invokeCallback(state, child, callback, result);
          });
        } else {
          $$$internal$$subscribe(parent, child, onFulfillment, onRejection);
        }

        return child;
      },

    /**
      `catch` is simply sugar for `then(undefined, onRejection)` which makes it the same
      as the catch block of a try/catch statement.

      ```js
      function findAuthor(){
        throw new Error('couldn't find that author');
      }

      // synchronous
      try {
        findAuthor();
      } catch(reason) {
        // something went wrong
      }

      // async with promises
      findAuthor().catch(function(reason){
        // something went wrong
      });
      ```

      @method catch
      @param {Function} onRejection
      Useful for tooling.
      @return {Promise}
    */
      'catch': function(onRejection) {
        return this.then(null, onRejection);
      }
    };

    var $$es6$promise$polyfill$$default = function polyfill() {
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
          return $$utils$$isFunction(resolve);
        }());

      if (!es6PromiseSupport) {
        local.Promise = $$es6$promise$promise$$default;
      }
    };

    var es6$promise$umd$$ES6Promise = {
      'Promise': $$es6$promise$promise$$default,
      'polyfill': $$es6$promise$polyfill$$default
    };

    /* global define:true module:true window: true */
    if (typeof define === 'function' && define['amd']) {
      define(function() { return es6$promise$umd$$ES6Promise; });
    } else if (typeof module !== 'undefined' && module['exports']) {
      module['exports'] = es6$promise$umd$$ES6Promise;
    } else if (typeof this !== 'undefined') {
      this['ES6Promise'] = es6$promise$umd$$ES6Promise;
    }
}).call(this);
  
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
   */

  Context.prototype.subscribeToDomainEvent = function(domainEventName, handlerFn) {
    var domainEventHandler;
    domainEventHandler = (function(_this) {
      return function() {
        return handlerFn.apply(_this._di, arguments);
      };
    })(this);
    return this._eventBus.subscribeToDomainEvent(domainEventName, domainEventHandler);
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
   */

  Context.prototype.subscribeToDomainEventWithAggregateId = function(domainEventName, aggregateId, handlerFn) {
    var domainEventHandler;
    domainEventHandler = (function(_this) {
      return function() {
        return handlerFn.apply(_this._di, arguments);
      };
    })(this);
    return this._eventBus.subscribeToDomainEventWithAggregateId(domainEventName, aggregateId, domainEventHandler);
  };


  /**
  * @name subscribeToAllDomainEvents
  * @module Context
  * @description Add handler function which gets called when any `DomainEvent` gets triggered
  *
  * @param {Function} Function which gets called with `domainEvent` as argument
   */

  Context.prototype.subscribeToAllDomainEvents = function(handlerFn) {
    var domainEventHandler;
    domainEventHandler = (function(_this) {
      return function() {
        return handlerFn.apply(_this._di, arguments);
      };
    })(this);
    return this._eventBus.subscribeToAllDomainEvents(domainEventHandler);
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
    return this._pubSub.subscribe(eventName, handlerFn);
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
    return new Promise((function(_this) {
      return function(resolve, reject) {
        return _this._pubSub.publish('DomainEvent', domainEvent).then(function() {
          return _this._pubSub.publish(domainEvent.name, domainEvent);
        }).then(function() {
          if (domainEvent.aggregate && domainEvent.aggregate.id) {
            return _this._pubSub.publish("" + domainEvent.name + "/" + domainEvent.aggregate.id, domainEvent).then(function() {
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
          return _this._context.subscribeToDomainEventStream(domainEventStreamName, domainEventHandler).then(function(subscriberId) {
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
              subscriberPromise = _this._context.subscribeToDomainEventWithAggregateId(eventName, aggregateId, domainEventHandler);
            } else {
              subscriberPromise = _this._context.subscribeToDomainEvent(eventName, domainEventHandler);
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
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.subscribe(this._contextName, handlerFn);
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
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.subscribe(this._contextName, domainEventName, handlerFn);
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
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.subscribe(this._contextName, domainEventName, aggregateId, handlerFn);
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
          if (err) {
            callback(err, null);
            return reject(err);
          } else {
            return _this._eventric.eachSeries(domainEvents, function(domainEvent, next) {
              _this._eventric.log.debug("Publishing DomainEvent", domainEvent);
              return _this._context.getEventBus().publishDomainEvent(domainEvent).then(function() {
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


  /**
  * @name subscribe
  *
  * @module InMemoryRemoteClient
   */

  InMemoryRemoteClient.prototype.subscribe = function() {
    var aggregateId, contextName, domainEventName, fullEventName, handlerFn, _arg, _i;
    contextName = arguments[0], _arg = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), handlerFn = arguments[_i++];
    domainEventName = _arg[0], aggregateId = _arg[1];
    fullEventName = getFullEventName(contextName, domainEventName, aggregateId);
    return pubSub.subscribe(fullEventName, handlerFn);
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
