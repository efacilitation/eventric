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
