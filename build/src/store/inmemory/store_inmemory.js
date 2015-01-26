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
