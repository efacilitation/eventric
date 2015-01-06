
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
    if (options.isAsync) {
      return this._pubSub.subscribeAsync(eventName, handlerFn);
    } else {
      return this._pubSub.subscribe(eventName, handlerFn);
    }
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
    return this._publish('publish', domainEvent);
  };


  /**
  * @name publishDomainEventAndWait
  * @module EventBus
  * @description Publish a DomainEvent on the Bus and wait for all Projections to call their promise.resolve
   */

  EventBus.prototype.publishDomainEventAndWait = function(domainEvent) {
    return this._publish('publishAsync', domainEvent);
  };

  EventBus.prototype._publish = function(publishMethod, domainEvent) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        return _this._pubSub[publishMethod]('DomainEvent', domainEvent).then(function() {
          return _this._pubSub[publishMethod](domainEvent.name, domainEvent);
        }).then(function() {
          if (domainEvent.aggregate && domainEvent.aggregate.id) {
            return _this._pubSub[publishMethod]("" + domainEvent.name + "/" + domainEvent.aggregate.id, domainEvent).then(function() {
              return resolve();
            });
          } else {
            return resolve();
          }
        });
      };
    })(this));
  };

  return EventBus;

})();

module.exports = EventBus;
