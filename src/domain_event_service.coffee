_ = require 'underscore'
Backbone = require 'backbone'

class DomainEventService

  _.extend @prototype, Backbone.Events

  constructor: (@_eventStore) ->

  saveAndTrigger: (domainEvents, callback) ->
    # TODO, this should be an transaction to guarantee the consistency of the aggregate

    for domainEvent in domainEvents

      # store the DomainEvent
      @_eventStore.save domainEvent, (err) =>
        return callback err if err

        # now trigger the DomainEvent in multiple fashions
        @trigger 'DomainEvent', domainEvent
        @trigger domainEvent.aggregate.name, domainEvent
        @trigger "#{domainEvent.aggregate.name}:#{domainEvent.name}", domainEvent
        @trigger "#{domainEvent.aggregate.name}/#{domainEvent.aggregate.id}", domainEvent
        @trigger "#{domainEvent.aggregate.name}:#{domainEvent.name}/#{domainEvent.aggregate.id}", domainEvent

    callback null


module.exports = DomainEventService
