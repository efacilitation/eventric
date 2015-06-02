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
