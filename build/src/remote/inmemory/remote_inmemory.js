var InMemoryRemoteClient, InMemoryRemoteEndpoint, PubSub, customRemoteBridge, getFullEventName, pubSub,
  __slice = [].slice;

PubSub = require('../../pub_sub');

customRemoteBridge = null;

pubSub = new PubSub;

InMemoryRemoteEndpoint = (function() {
  function InMemoryRemoteEndpoint() {
    customRemoteBridge = (function(_this) {
      return function(rpcRequest) {
        return new Promise(function(resolve, reject) {
          return _this._handleRPCRequest(rpcRequest, function(error, result) {
            if (error) {
              return reject(error);
            }
            return resolve(result);
          });
        });
      };
    })(this);
  }

  InMemoryRemoteEndpoint.prototype.setRPCHandler = function(_handleRPCRequest) {
    this._handleRPCRequest = _handleRPCRequest;
  };

  InMemoryRemoteEndpoint.prototype.publish = function() {
    var aggregateId, contextName, domainEventName, fullEventName, payload, _arg, _i;
    contextName = arguments[0], _arg = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), payload = arguments[_i++];
    domainEventName = _arg[0], aggregateId = _arg[1];
    fullEventName = getFullEventName(contextName, domainEventName, aggregateId);
    return pubSub.publish(fullEventName, payload);
  };

  return InMemoryRemoteEndpoint;

})();

module.exports.endpoint = new InMemoryRemoteEndpoint;

InMemoryRemoteClient = (function() {
  function InMemoryRemoteClient() {}

  InMemoryRemoteClient.prototype.rpc = function(rpcRequest) {
    if (!customRemoteBridge) {
      throw new Error('No Remote Endpoint available for in memory client');
    }
    return customRemoteBridge(rpcRequest);
  };

  InMemoryRemoteClient.prototype.subscribe = function() {
    var aggregateId, contextName, domainEventName, fullEventName, handlerFn, _arg, _i;
    contextName = arguments[0], _arg = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), handlerFn = arguments[_i++];
    domainEventName = _arg[0], aggregateId = _arg[1];
    fullEventName = getFullEventName(contextName, domainEventName, aggregateId);
    return pubSub.subscribe(fullEventName, handlerFn);
  };

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
