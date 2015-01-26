
/**
* @name Remote
* @module Remote
* @description
*
* Remotes let you remotely use Contexts
 */
var Remote;

Remote = (function() {
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
    this.projectionService = new this._eventric.Projection(this._eventric);
    this.addClient('inmemory', this.InMemoryRemote.client);
    this.set('default client', 'inmemory');
  }


  /**
  * @name set
  * @module Remote
  * @description Configure Remote parameters
  *
  * @example
  
     exampleRemote.set 'store', StoreAdapter
  
  *
  * @param {String} key Name of the key
  * @param {Mixed} value Value to be set
   */

  Remote.prototype.set = function(key, value) {
    this._params[key] = value;
    return this;
  };


  /**
  * @name get
  * @module Remote
  * @description Get configured Remote parameters
  *
  * @example
  
     exampleRemote.set 'store', StoreAdapter
  
  *
  * @param {String} key Name of the Key
   */

  Remote.prototype.get = function(key) {
    return this._params[key];
  };


  /**
  * @name command
  * @module Remote
  * @description Execute previously added CommandHandlers
  *
  * @example
    ```javascript
    exampleRemote.command('doSomething');
    ```
  *
  * @param {String} `commandName` Name of the CommandHandler to be executed
  * @param {Object} `commandParams` Parameters for the CommandHandler function
   */

  Remote.prototype.command = function() {
    return this._rpc('command', arguments);
  };


  /**
  * @name query
  * @module Remote
  * @description Execute previously added QueryHandler
  *
  * @example
    ```javascript
    exampleRemote.query('getSomething');
    ```
  *
  * @param {String} `queryName` Name of the QueryHandler to be executed
  * @param {Object} `queryParams` Parameters for the QueryHandler function
   */

  Remote.prototype.query = function() {
    return this._rpc('query', arguments);
  };


  /**
  * @name findAllDomainEvents
  * @module Remote
  * @description Return all DomainEvents from the default DomainEventStore
   */

  Remote.prototype.findAllDomainEvents = function() {
    return this._rpc('findAllDomainEvents', arguments);
  };


  /**
  * @name findDomainEventsByName
  * @module Remote
  * @description Return DomainEvents from the default DomainEventStore which match the given DomainEventName
  *
  * @param {String} domainEventName Name of the DomainEvent to be returned
   */

  Remote.prototype.findDomainEventsByName = function() {
    return this._rpc('findDomainEventsByName', arguments);
  };


  /**
  * @name findDomainEventsByAggregateId
  * @module Remote
  * @description Return DomainEvents from the default DomainEventStore which match the given AggregateId
  *
  * @param {String} aggregateId AggregateId of the DomainEvents to be found
   */

  Remote.prototype.findDomainEventsByAggregateId = function() {
    return this._rpc('findDomainEventsByAggregateId', arguments);
  };


  /**
  * @name findDomainEventsByAggregateName
  * @module Remote
  * @description Return DomainEvents from the default DomainEventStore which match the given AggregateName
  *
  * @param {String} aggregateName AggregateName of the DomainEvents to be found
   */

  Remote.prototype.findDomainEventsByAggregateName = function() {
    return this._rpc('findDomainEventsByAggregateName', arguments);
  };


  /**
  * @name findDomainEventsByNameAndAggregateId
  * @module Remote
  * @description Return DomainEvents from the default DomainEventStore which match the given DomainEventName and AggregateId
  *
  * @param {String} domainEventName Name of the DomainEvents to be found
  * @param {String} aggregateId AggregateId of the DomainEvents to be found
   */

  Remote.prototype.findDomainEventsByNameAndAggregateId = function() {
    return this._rpc('findDomainEventsByNameAndAggregateId', arguments);
  };


  /**
  * @name subscribeToAllDomainEvents
  * @module Remote
  * @description Add handler function which gets called when any `DomainEvent` gets triggered
  *
  * @param {Function} Function which gets called with `domainEvent` as argument
   */

  Remote.prototype.subscribeToAllDomainEvents = function(handlerFn) {
    return this._rps('subscribeToAllDomainEvents', handlerFn);
  };


  /**
  * @name subscribeToDomainEvent
  * @module Remote
  * @description Add handler function which gets called when a specific `DomainEvent` gets triggered
  *
  * @example
    ```javascript
    exampleRemote.subscribeToDomainEvent('SomethingHappened', function(domainEvent) {
      // ...
    });
    ```
  *
  * @param {String} domainEventName Name of the `DomainEvent`
  * @param {Function} Function which gets called with `domainEvent` as argument
   */

  Remote.prototype.subscribeToDomainEvent = function(domainEventName, handlerFn) {
    return this._rps('subscribeToDomainEvent', handlerFn, [domainEventName]);
  };


  /**
  * @name subscribeToDomainEventWithAggregateId
  * @module Remote
  * @description Add handler function which gets called when a specific `DomainEvent` containing a specific AggregateId gets triggered
  *
  * @param {String} domainEventName Name of the `DomainEvent`
  * @param {String} aggregateId AggregateId
  * @param {Function} Function which gets called with `domainEvent` as argument
   */

  Remote.prototype.subscribeToDomainEventWithAggregateId = function(domainEventName, aggregateId, handlerFn) {
    return this._rps('subscribeToDomainEventWithAggregateId', handlerFn, [domainEventName, aggregateId]);
  };


  /**
  * @name subscribeToDomainEventWithAggregateId
  * @module Remote
  * @description Add handler function which gets called when a specific `DomainEvent` containing a specific AggregateId gets triggered
  *
  * @param {String} domainEventStreamName Name of the `DomainEvent`
  * @param {Function} Function which gets called with `domainEvent` as argument
   */

  Remote.prototype.subscribeToDomainEventStream = function() {
    return this._rpc('subscribeToDomainEventStream', arguments);
  };


  /**
  * @name unsubscribeFromDomainEvent
  * @module Remote
  * @description Unsubscribe from a DomainEvent
  *
  * @param {String} subscriber SubscriberId
   */

  Remote.prototype.unsubscribeFromDomainEvent = function(subscriberId) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.unsubscribe(subscriberId);
  };

  Remote.prototype._rps = function(method, subscriberFn, params) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.subscribe({
      contextName: this._contextName,
      method: method,
      params: params
    }, {
      id: this._eventric.generateUid(),
      fn: subscriberFn
    });
  };

  Remote.prototype._rpc = function(method, params) {
    var client, clientName;
    clientName = this.get('default client');
    client = this.getClient(clientName);
    return client.rpc({
      contextName: this._contextName,
      method: method,
      params: Array.prototype.slice.call(params)
    });
  };


  /**
  * @name addClient
  * @module Remote
  * @description Add a RemoteClient
  *
  * @param {String} clientName Name of the Client
  * @param {Object} client Object containing an initialized Client
   */

  Remote.prototype.addClient = function(clientName, client) {
    this._clients[clientName] = client;
    return this;
  };


  /**
  * @name getClient
  * @module Remote
  * @description Get a RemoteClient
  *
  * @param {String} clientName Name of the Client
   */

  Remote.prototype.getClient = function(clientName) {
    return this._clients[clientName];
  };


  /**
  * @name addProjection
  * @module Remote
  * @description Add Projection that can subscribe to and handle DomainEvents
  *
  * @param {string} projectionName Name of the Projection
  * @param {Function} The Projection Class definition
   */

  Remote.prototype.addProjection = function(projectionName, projectionClass) {
    this._projectionClasses[projectionName] = projectionClass;
    return this;
  };


  /**
  * @name initializeProjection
  * @module Remote
  * @description Initialize a Projection based on an Object
  *
  * @param {Object} projectionObject Projection Object
  * @param {Object} params Object containing Projection Parameters
   */

  Remote.prototype.initializeProjection = function(projectionObject, params) {
    return this.projectionService.initializeInstance('', projectionObject, params, this);
  };


  /**
  * @name initializeProjectionInstance
  * @module Remote
  * @description Initialize a ProjectionInstance
  *
  * @param {String} projectionId ProjectionId
  * @param {Object} params Object containing Projection Parameters
   */

  Remote.prototype.initializeProjectionInstance = function(projectionName, params) {
    var err;
    if (!this._projectionClasses[projectionName]) {
      err = "Given projection " + projectionName + " not registered on remote";
      this._eventric.log.error(err);
      err = new Error(err);
      return err;
    }
    return this.projectionService.initializeInstance(projectionName, this._projectionClasses[projectionName], params, this);
  };


  /**
  * @name getProjectionInstance
  * @module Remote
  * @description Get a Projection Instance
  *
  * @param {String} projectionId ProjectionId
   */

  Remote.prototype.getProjectionInstance = function(projectionId) {
    return this.projectionService.getInstance(projectionId);
  };


  /**
  * @name destroyProjectionInstance
  * @module Remote
  * @description Destroy a ProjectionInstance
  *
  * @param {String} projectionId ProjectionId
   */

  Remote.prototype.destroyProjectionInstance = function(projectionId) {
    return this.projectionService.destroyInstance(projectionId, this);
  };

  return Remote;

})();

module.exports = Remote;
