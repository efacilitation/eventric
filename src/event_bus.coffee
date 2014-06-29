HelperEvents = eventric.require 'HelperEvents'

class EventBus

  _.extend @prototype, HelperEvents

  subscribeToDomainEvent: (domainEventName, domainEventHandler) ->
    @on domainEventName, domainEventHandler


  publishDomainEvent: (domainEvent) ->
    @trigger 'DomainEvent', domainEvent
    @trigger domainEvent.name, domainEvent


module.exports = EventBus