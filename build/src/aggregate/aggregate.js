
/**
* @name Aggregate
* @module Aggregate
* @description
*
* Aggregates live inside a Context and give you basically transactional boundaries
* for your Behaviors and DomainEvents.
 */
var Aggregate,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Aggregate = (function() {
  function Aggregate(_context, _eventric, _name, Root) {
    this._context = _context;
    this._eventric = _eventric;
    this._name = _name;
    this.getDomainEvents = __bind(this.getDomainEvents, this);
    this.emitDomainEvent = __bind(this.emitDomainEvent, this);
    this._domainEvents = [];
    if (!Root) {
      this.root = {};
    } else {
      this.root = new Root;
    }
    this.root.$emitDomainEvent = this.emitDomainEvent;
  }


  /**
  * @name emitDomainEvent
  * @module Aggregate
  * @description Emit DomainEvent
  *
  * @param {String} domainEventName Name of the DomainEvent
  * @param {Object} domainEventPayload Object containing the payload of the DomainEvent
   */

  Aggregate.prototype.emitDomainEvent = function(domainEventName, domainEventPayload) {
    var DomainEventClass, domainEvent, err;
    DomainEventClass = this._context.getDomainEvent(domainEventName);
    if (!DomainEventClass) {
      err = "Tried to emitDomainEvent '" + domainEventName + "' which is not defined";
      this._eventric.log.error(err);
      throw new Error(err);
    }
    domainEvent = this._createDomainEvent(domainEventName, DomainEventClass, domainEventPayload);
    this._domainEvents.push(domainEvent);
    this._handleDomainEvent(domainEventName, domainEvent);
    return this._eventric.log.debug("Created and Handled DomainEvent in Aggregate", domainEvent);
  };

  Aggregate.prototype._createDomainEvent = function(domainEventName, DomainEventClass, domainEventPayload) {
    return new this._eventric.DomainEvent({
      id: this._eventric.generateUid(),
      name: domainEventName,
      aggregate: {
        id: this.id,
        name: this._name
      },
      context: this._context.name,
      payload: new DomainEventClass(domainEventPayload)
    });
  };

  Aggregate.prototype._handleDomainEvent = function(domainEventName, domainEvent) {
    if (this.root["handle" + domainEventName]) {
      return this.root["handle" + domainEventName](domainEvent, function() {});
    } else {
      return this._eventric.log.debug("Tried to handle the DomainEvent '" + domainEventName + "' without a matching handle method");
    }
  };


  /**
  * @name getDomainEvents
  * @module Aggregate
  * @description Get all emitted DomainEvents
   */

  Aggregate.prototype.getDomainEvents = function() {
    return this._domainEvents;
  };


  /**
  * @name applyDomainEvents
  * @module Context
  * @description Apply DomainEvents to the Aggregate
  *
  * @param {Array} domainEvents Array containing DomainEvents
   */

  Aggregate.prototype.applyDomainEvents = function(domainEvents) {
    var domainEvent, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = domainEvents.length; _i < _len; _i++) {
      domainEvent = domainEvents[_i];
      _results.push(this._applyDomainEvent(domainEvent));
    }
    return _results;
  };

  Aggregate.prototype._applyDomainEvent = function(domainEvent) {
    return this._handleDomainEvent(domainEvent.name, domainEvent);
  };

  return Aggregate;

})();

module.exports = Aggregate;
