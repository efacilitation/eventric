_ = require 'underscore'
Backbone = require 'backbone'

class DomainEventService

  _.extend @prototype, Backbone.Events

  constructor: (@_eventStore) ->
    @_handlers = {}


  saveAndTrigger: (domainEvents) ->

    for domainEvent in domainEvents

      # store the DomainEvent
      @_eventStore.save domainEvent, (err) =>

        # now trigger the DomainEvent in multiple fashions
        @trigger 'DomainEvent', domainEvent
        @trigger domainEvent.aggregate.name, domainEvent
        @trigger domainEvent.aggregate.name + '/' + domainEvent.aggregate.id, domainEvent
        @trigger domainEvent.aggregate.name + ':' + domainEvent.name, domainEvent
        @trigger domainEvent.aggregate.name + ':' + domainEvent.name + '/' + domainEvent.aggregate.id, domainEvent


module.exports = DomainEventService
