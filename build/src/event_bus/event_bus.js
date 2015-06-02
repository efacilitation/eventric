var EventBus;

EventBus = (function() {
  function EventBus(_eventric) {
    this._eventric = _eventric;
    this._pubSub = new this._eventric.PubSub();
    this._publishQueue = new Promise(function(resolve) {
      return resolve();
    });
  }

  EventBus.prototype.subscribeToDomainEvent = function(eventName, handlerFn) {
    return this._pubSub.subscribe(eventName, handlerFn);
  };

  EventBus.prototype.subscribeToDomainEventWithAggregateId = function(eventName, aggregateId, handlerFn) {
    return this.subscribeToDomainEvent("" + eventName + "/" + aggregateId, handlerFn);
  };

  EventBus.prototype.subscribeToAllDomainEvents = function(handlerFn) {
    return this.subscribeToDomainEvent('DomainEvent', handlerFn);
  };

  EventBus.prototype.publishDomainEvent = function(domainEvent) {
    return this._enqueuePublishing((function(_this) {
      return function() {
        return _this._publishDomainEvent(domainEvent);
      };
    })(this));
  };

  EventBus.prototype._enqueuePublishing = function(publishOperation) {
    return this._publishQueue = this._publishQueue.then(publishOperation);
  };

  EventBus.prototype._publishDomainEvent = function(domainEvent) {
    var eventName, publishPasses, _ref;
    publishPasses = [this._pubSub.publish('DomainEvent', domainEvent), this._pubSub.publish(domainEvent.name, domainEvent)];
    if ((_ref = domainEvent.aggregate) != null ? _ref.id : void 0) {
      eventName = "" + domainEvent.name + "/" + domainEvent.aggregate.id;
      publishPasses.push(this._pubSub.publish(eventName, domainEvent));
    }
    return Promise.all(publishPasses);
  };

  EventBus.prototype.destroy = function() {
    return this._pubSub.destroy().then((function(_this) {
      return function() {
        return _this.publishDomainEvent = void 0;
      };
    })(this));
  };

  return EventBus;

})();

module.exports = EventBus;
