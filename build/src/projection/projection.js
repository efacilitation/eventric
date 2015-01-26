
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
