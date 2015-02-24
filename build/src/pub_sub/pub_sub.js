
/**
* @name PubSub
* @module PubSub
* @description
*
* Publish and Subscribe to arbitrary Events
 */
var PubSub,
  __slice = [].slice;

PubSub = (function() {
  function PubSub() {
    this._subscribers = [];
    this._subscriberId = 0;
    this._nextTick = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return setTimeout.apply(null, args);
    };
  }


  /**
  * @name subscribe
  * @module PubSub
  * @description Subscribe to an Event
  *
  * @param {String} eventName Name of the Event to subscribe to
  * @param {Function} subscriberFn Function to call when Event gets published
   */

  PubSub.prototype.subscribe = function(eventName, subscriberFn) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var subscriber;
        subscriber = {
          eventName: eventName,
          subscriberFn: subscriberFn,
          subscriberId: _this._getNextSubscriberId()
        };
        _this._subscribers.push(subscriber);
        return resolve(subscriber.subscriberId);
      };
    })(this));
  };


  /**
  * @name publish
  * @module PubSub
  * @description Publish an Event
  *
  * @param {String} eventName Name of the Event
  * @param {Object} payload The Event payload to be published
   */

  PubSub.prototype.publish = function(eventName, payload) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var executeNextHandler, subscribers;
        subscribers = _this._getRelevantSubscribers(eventName);
        executeNextHandler = function() {
          if (subscribers.length === 0) {
            return resolve();
          } else {
            subscribers.shift().subscriberFn(payload, function() {});
            return _this._nextTick(executeNextHandler, 0);
          }
        };
        return _this._nextTick(executeNextHandler, 0);
      };
    })(this));
  };

  PubSub.prototype._getRelevantSubscribers = function(eventName) {
    if (eventName) {
      return this._subscribers.filter(function(x) {
        return x.eventName === eventName;
      });
    } else {
      return this._subscribers;
    }
  };


  /**
  * @name unsubscribe
  * @module PubSub
  * @description Unscribe from an Event
  *
  * @param {String} subscriberId SubscriberId
   */

  PubSub.prototype.unsubscribe = function(subscriberId) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        _this._subscribers = _this._subscribers.filter(function(x) {
          return x.subscriberId !== subscriberId;
        });
        return resolve();
      };
    })(this));
  };

  PubSub.prototype._getNextSubscriberId = function() {
    return this._subscriberId++;
  };

  return PubSub;

})();

module.exports = PubSub;
