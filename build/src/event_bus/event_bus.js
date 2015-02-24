
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
    return this._pubSub.subscribe(eventName, handlerFn);
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
    return new Promise((function(_this) {
      return function(resolve, reject) {
        return _this._pubSub.publish('DomainEvent', domainEvent).then(function() {
          return _this._pubSub.publish(domainEvent.name, domainEvent);
        }).then(function() {
          if (domainEvent.aggregate && domainEvent.aggregate.id) {
            return _this._pubSub.publish("" + domainEvent.name + "/" + domainEvent.aggregate.id, domainEvent).then(function() {
              return resolve();
            });
          } else {
            return resolve();
          }
        })["catch"](function(err) {
          return reject(err);
        });
      };
    })(this));
  };

  return EventBus;

})();

module.exports = EventBus;
