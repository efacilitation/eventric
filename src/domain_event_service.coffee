_ = require 'underscore'
Backbone = require 'backbone'

class DomainEventService

  _.extend @prototype, Backbone.Events

  constructor: ->
    @_handlers = {}
    @_cache = []


  handle: (domainEvents) ->

    for domainEvent in domainEvents

      # loop all matching read models
      if @_handlers[domainEvent.data.model]
        readModels = @_handlers[domainEvent.data.model][domainEvent.data.id]
        for readModel in readModels
          readModel._applyChanges domainEvent._changed

      # store the DomainEvent into local cache
      @_storeInCache domainEvent

      # now trigger the DomainEvent
      @trigger 'DomainEvent', domainEvent

  _storeInCache: (domainEvent) ->
    @_cache.push domainEvent

# DomainEventService is a singelton!
domainEventService = new DomainEventService

module.exports = domainEventService
