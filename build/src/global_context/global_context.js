var GlobalContext,
  __slice = [].slice;

GlobalContext = (function() {
  function GlobalContext(_eventric) {
    this._eventric = _eventric;
    this.name = 'Global';
  }

  GlobalContext.prototype.findDomainEventsByName = function() {
    var findArguments, findDomainEventsByName;
    findArguments = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    findDomainEventsByName = this._getAllContexts().map(function(context) {
      return context.findDomainEventsByName.apply(context, findArguments);
    });
    return Promise.all(findDomainEventsByName).then((function(_this) {
      return function(domainEventsByContext) {
        var domainEvents;
        domainEvents = _this._combineDomainEventsByContext(domainEventsByContext);
        return _this._sortDomainEventsByTimestamp(domainEvents);
      };
    })(this));
  };

  GlobalContext.prototype.subscribeToDomainEvent = function(eventName, domainEventHandler) {
    var subscribeToDomainEvents;
    subscribeToDomainEvents = this._getAllContexts().map(function(context) {
      return context.subscribeToDomainEvent(eventName, domainEventHandler);
    });
    return Promise.all(subscribeToDomainEvents);
  };

  GlobalContext.prototype._getAllContexts = function() {
    var contextNames;
    contextNames = this._eventric.getRegisteredContextNames();
    return contextNames.map((function(_this) {
      return function(contextName) {
        return _this._eventric.remote(contextName);
      };
    })(this));
  };

  GlobalContext.prototype._combineDomainEventsByContext = function(domainEventsByContext) {
    return domainEventsByContext.reduce(function(allDomainEvents, contextDomainEvents) {
      return allDomainEvents.concat(contextDomainEvents);
    }, []);
  };

  GlobalContext.prototype._sortDomainEventsByTimestamp = function(domainEvents) {
    return domainEvents.sort(function(firstEvent, secondEvent) {
      return firstEvent.timestamp - secondEvent.timestamp;
    });
  };

  return GlobalContext;

})();

module.exports = GlobalContext;
