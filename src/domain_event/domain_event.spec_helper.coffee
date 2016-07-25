DomainEvent = require './domain_event'
uuidGenerator = require 'eventric/uuid_generator'

class DomainEventSpecHelper

  createDomainEvent: (domainEventName = 'DomainEventName', payload = {}) ->
    return new DomainEvent
      name: domainEventName
      aggregate:
        id: uuidGenerator.generateUuid()
        name: 'SampleAggregate'
      context: 'SampleContext'
      payload: payload


module.exports = new DomainEventSpecHelper
