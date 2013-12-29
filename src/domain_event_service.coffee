_ = require 'underscore'
Backbone = require 'backbone'

class DomainEventService

  _.extend @prototype, Backbone.Events

  constructor: ->
    @handlers = {}


  handle: (domainEvents) ->

    for domainEvent in domainEvents

      # loop all matching read models
      if @handlers[domainEvent.data.model]
        readModels = @handlers[domainEvent.data.model][domainEvent.data.id]
        for readModel in readModels
          readModel._applyChanges domainEvent.changed

      # now trigger the domainevent
      @trigger 'DomainEvent', domainEvent

# DomainEventService is a singelton!
domainEventService = new DomainEventService

module.exports = domainEventService
