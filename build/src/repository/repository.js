
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
          var domainEvent, _i, _len;
          if (err) {
            callback(err, null);
            return reject(err);
          } else {
            if (!_this._context.isWaitingModeEnabled()) {
              for (_i = 0, _len = domainEvents.length; _i < _len; _i++) {
                domainEvent = domainEvents[_i];
                _this._eventric.log.debug("Publishing DomainEvent", domainEvent);
                _this._context.getEventBus().publishDomainEvent(domainEvent);
              }
              resolve(aggregate.id);
              return callback(null, aggregate.id);
            } else {
              return _this._eventric.eachSeries(domainEvents, function(domainEvent, next) {
                _this._eventric.log.debug("Publishing DomainEvent in waiting mode", domainEvent);
                return _this._context.getEventBus().publishDomainEventAndWait(domainEvent).then(function() {
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
