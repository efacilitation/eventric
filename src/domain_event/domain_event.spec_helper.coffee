DomainEvent = require './domain_event'
domainEventIdGenerator = require 'eventric/aggregate/domain_event_id_generator'
uuidGenerator = require 'eventric/uuid_generator'

class DomainEventSpecHelper

  generateDomainEvent: (domainEventName = 'DomainEventName', payload = {}) ->
    id: domainEventIdGenerator.generateId()
    name: domainEventName
    aggregate:
      id: uuidGenerator.generateUuid()
      name: 'SampleAggregate'
    context: 'SampleContext'
    payload: payload


module.exports = new DomainEventSpecHelper
