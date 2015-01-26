
/**
* @name DomainEvent
* @module DomainEvent
* @description
*
* DomainEvents are the most important and most easy building block.
 */
var DomainEvent;

DomainEvent = (function() {
  function DomainEvent(params) {
    this.id = params.id;
    this.name = params.name;
    this.payload = params.payload;
    this.aggregate = params.aggregate;
    this.context = params.context;
    this.timestamp = new Date().getTime();
  }

  return DomainEvent;

})();

module.exports = DomainEvent;
