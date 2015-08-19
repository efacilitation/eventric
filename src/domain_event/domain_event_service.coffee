class DomainEventService

  sortDomainEventsById: (domainEvents) ->
    domainEvents.sort (firstDomainEvent, secondDomainEvent) ->
      firstDomainEvent.id - secondDomainEvent.id


module.exports = new DomainEventService
