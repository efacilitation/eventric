var InMemoryStore, STORE_SUPPORTS,
  __slice = [].slice;

STORE_SUPPORTS = ['domain_events', 'projections'];

InMemoryStore = (function() {
  function InMemoryStore() {}

  InMemoryStore.prototype._domainEvents = {};

  InMemoryStore.prototype._projections = {};

  InMemoryStore.prototype.initialize = function() {
    var callback, options, _arg, _context, _i;
    _context = arguments[0], _arg = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), callback = arguments[_i++];
    this._context = _context;
    options = _arg[0];
    this._domainEventsCollectionName = "" + this._context.name + ".DomainEvents";
    this._projectionCollectionName = "" + this._context.name + ".Projections";
    this._domainEvents[this._domainEventsCollectionName] = [];
    return callback();
  };


  /**
  * @name saveDomainEvent
  *
  * @module InMemoryStore
   */

  InMemoryStore.prototype.saveDomainEvent = function(domainEvent, callback) {
    this._domainEvents[this._domainEventsCollectionName].push(domainEvent);
    return callback(null, domainEvent);
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


  /**
  * @name clearProjectionStore
  *
  * @module InMemoryStore
   */

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
