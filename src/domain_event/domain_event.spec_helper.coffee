DomainEvent = require './domain_event'
uuidGenerator = require 'eventric/uuid_generator'

class DomainEventSpecHelper

  constructor: ->
    @_currentDomainEventId = 1


  createDomainEvent: (domainEventName = 'DomainEventName', payload = {}) ->
    return new DomainEvent
      id: @_currentDomainEventId++
      name: domainEventName
      aggregate:
        id: uuidGenerator.generateUuid()
        name: 'SampleAggregate'
      context: 'SampleContext'
      payload: payload


module.exports = new DomainEventSpecHelper
