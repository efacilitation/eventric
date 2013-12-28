class DomainEventService

  constructor: ->
    @handlers = {}


  handle: (domainEvents) ->

    for domainEvent in domainEvents

      # loop all matching read models
      readModels = @handlers[domainEvent.data.model][domainEvent.data.id]
      for readModel in readModels
        readModel._applyChanges domainEvent.changed

# DomainEventService is a singelton!
domainEventService = new DomainEventService

module.exports = domainEventService
