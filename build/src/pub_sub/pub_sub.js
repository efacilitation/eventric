var PubSub;

PubSub = (function() {
  function PubSub() {
    this._subscribers = [];
    this._subscriberId = 0;
    this._pendingPublishOperations = [];
  }

  PubSub.prototype.subscribe = function(eventName, subscriberFunction) {
    return new Promise((function(_this) {
      return function(resolve) {
        var subscriber;
        subscriber = {
          eventName: eventName,
          subscriberFunction: subscriberFunction,
          subscriberId: _this._getNextSubscriberId()
        };
        _this._subscribers.push(subscriber);
        return resolve(subscriber.subscriberId);
      };
    })(this));
  };

  PubSub.prototype.publish = function(eventName, payload) {
    var executeSubscriberFunctions, subscribers;
    subscribers = this._getRelevantSubscribers(eventName);
    executeSubscriberFunctions = Promise.all(subscribers.map(function(subscriber) {
      return subscriber.subscriberFunction(payload);
    }));
    this._addPendingPublishOperation(executeSubscriberFunctions);
    return executeSubscriberFunctions;
  };

  PubSub.prototype._getRelevantSubscribers = function(eventName) {
    if (eventName) {
      return this._subscribers.filter(function(subscriber) {
        return subscriber.eventName === eventName;
      });
    } else {
      return this._subscribers;
    }
  };

  PubSub.prototype._addPendingPublishOperation = function(publishOperation) {
    this._pendingPublishOperations.push(publishOperation);
    return publishOperation.then((function(_this) {
      return function() {
        return _this._pendingPublishOperations.splice(_this._pendingPublishOperations.indexOf(publishOperation), 1);
      };
    })(this));
  };

  PubSub.prototype.unsubscribe = function(subscriberId) {
    return new Promise((function(_this) {
      return function(resolve) {
        _this._subscribers = _this._subscribers.filter(function(subscriber) {
          return subscriber.subscriberId !== subscriberId;
        });
        return resolve();
      };
    })(this));
  };

  PubSub.prototype._getNextSubscriberId = function() {
    return this._subscriberId++;
  };

  PubSub.prototype.destroy = function() {
    return Promise.all(this._pendingPublishOperations).then((function(_this) {
      return function() {
        return _this.publish = void 0;
      };
    })(this));
  };

  return PubSub;

})();

module.exports = PubSub;
