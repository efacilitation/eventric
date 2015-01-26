var InMemoryRemoteClient, InMemoryRemoteEndpoint, PubSub, customRemoteBridge, getFullEventName, pubSub, subscribers,
  __slice = [].slice;

PubSub = require('../../pub_sub');

customRemoteBridge = null;

subscribers = {};

pubSub = new PubSub;

InMemoryRemoteEndpoint = (function() {
  function InMemoryRemoteEndpoint() {
    customRemoteBridge = (function(_this) {
      return function(rpcRequest) {
        return _this._handleRPCRequest(rpcRequest);
      };
    })(this);
  }


  /**
  * @name setRPCHandler
  *
  * @module InMemoryRemoteEndpoint
   */

  InMemoryRemoteEndpoint.prototype.setRPCHandler = function(_handleRPCRequest) {
    this._handleRPCRequest = _handleRPCRequest;
  };


  /**
  * @name publish
  *
  * @module InMemoryRemoteEndpoint
   */

  InMemoryRemoteEndpoint.prototype.publish = function() {
    var aggregateId, contextName, domainEventName, fullEventName, payload, _arg, _i;
    contextName = arguments[0], _arg = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), payload = arguments[_i++];
    domainEventName = _arg[0], aggregateId = _arg[1];
    fullEventName = getFullEventName(contextName, domainEventName, aggregateId);
    return pubSub.publish(fullEventName, payload, function() {});
  };

  return InMemoryRemoteEndpoint;

})();

module.exports.endpoint = new InMemoryRemoteEndpoint;

InMemoryRemoteClient = (function() {
  function InMemoryRemoteClient() {}


  /**
  * @name rpc
  *
  * @module InMemoryRemoteClient
   */

  InMemoryRemoteClient.prototype.rpc = function(rpcRequest) {
    if (!customRemoteBridge) {
      throw new Error('No Remote Endpoint available for in memory client');
    }
    return customRemoteBridge(rpcRequest);
  };

  InMemoryRemoteClient.prototype.subscribe = function(rpcRequest, subscriber) {
    rpcRequest.params.push(subscriber.fn);
    return customRemoteBridge(rpcRequest);
  };


  /**
  * @name unsubscribe
  *
  * @module InMemoryRemoteClient
   */

  InMemoryRemoteClient.prototype.unsubscribe = function(subscriberId) {
    return pubSub.unsubscribe(subscriberId);
  };

  return InMemoryRemoteClient;

})();

module.exports.client = new InMemoryRemoteClient;

getFullEventName = function(contextName, domainEventName, aggregateId) {
  var fullEventName;
  fullEventName = contextName;
  if (domainEventName) {
    fullEventName += "/" + domainEventName;
  }
  if (aggregateId) {
    fullEventName += "/" + aggregateId;
  }
  return fullEventName;
};
