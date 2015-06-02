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
