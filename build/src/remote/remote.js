var Remote;

Remote = (function() {
  Remote.ALLOWED_RPC_OPERATIONS = ['command', 'query', 'findDomainEventsByName', 'findDomainEventsByNameAndAggregateId'];

  function Remote(_contextName, _eventric) {
    this._contextName = _contextName;
    this._eventric = _eventric;
    this.name = this._contextName;
    this.InMemoryRemote = require('./inmemory');
    this._params = {};
    this._clients = {};
    this._projectionClasses = {};
    this._projectionInstances = {};
    this._handlerFunctions = {};
    this.projectionService = new this._eventric.Projection(this._eventric, this);
    this.addClient('inmemory', this.InMemoryRemote.client);
    this.set('default client', 'inmemory');
    this._exposeRpcOperationsAsMemberFunctions();
  }

  Remote.prototype._exposeRpcOperationsAsMemberFunctions = function() {
    return Remote.ALLOWED_RPC_OPERATIONS.forEach((function(_this) {
      return function(rpcOperation) {
        return _this[rpcOperation] = function() {
          return _this._rpc(rpcOperation, arguments);
        };
      };
    })(this));
  };

  Remote.prototype.set = function(key, value) {
    this._params[key] = value;
    return this;
  };

  Remote.prototype.get = function(key) {
    return this._params[key];
  };

  Remote.prototype.subscribeToAllDomainEvents = function(handlerFn) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.subscribe(this._contextName, handlerFn);
  };

  Remote.prototype.subscribeToDomainEvent = function(domainEventName, handlerFn) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.subscribe(this._contextName, domainEventName, handlerFn);
  };

  Remote.prototype.subscribeToDomainEventWithAggregateId = function(domainEventName, aggregateId, handlerFn) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.subscribe(this._contextName, domainEventName, aggregateId, handlerFn);
  };

  Remote.prototype.unsubscribeFromDomainEvent = function(subscriberId) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.unsubscribe(subscriberId);
  };

  Remote.prototype._rpc = function(functionName, args) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.rpc({
      contextName: this._contextName,
      functionName: functionName,
      args: Array.prototype.slice.call(args)
    });
  };

  Remote.prototype.addClient = function(clientName, client) {
    this._clients[clientName] = client;
    return this;
  };

  Remote.prototype.getClient = function(clientName) {
    return this._clients[clientName];
  };

  Remote.prototype.addProjection = function(projectionName, projectionClass) {
    this._projectionClasses[projectionName] = projectionClass;
    return this;
  };

  Remote.prototype.initializeProjection = function(projectionObject, params) {
    return this.projectionService.initializeInstance('', projectionObject, params);
  };

  Remote.prototype.initializeProjectionInstance = function(projectionName, params) {
    var err;
    if (!this._projectionClasses[projectionName]) {
      err = "Given projection " + projectionName + " not registered on remote";
      this._eventric.log.error(err);
      err = new Error(err);
      return err;
    }
    return this.projectionService.initializeInstance(projectionName, this._projectionClasses[projectionName], params);
  };

  Remote.prototype.getProjectionInstance = function(projectionId) {
    return this.projectionService.getInstance(projectionId);
  };

  Remote.prototype.destroyProjectionInstance = function(projectionId) {
    return this.projectionService.destroyInstance(projectionId, this);
  };

  return Remote;

})();

module.exports = Remote;
