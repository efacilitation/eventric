DomainEvent = require './domain_event'
domainEventIdGenerator = require 'eventric/aggregate/domain_event_id_generator'
uuidGenerator = require 'eventric/uuid_generator'

class DomainEventSpecHelper

  createDomainEvent: (domainEventName = 'DomainEventName', payload = {}) ->
    new DomainEvent
      id: domainEventIdGenerator.generateId()
      name: domainEventName
      aggregate:
        id: uuidGenerator.generateUuid()
        name: 'SampleAggregate'
      context: 'SampleContext'
      payload: payload


module.exports = new DomainEventSpecHelper
