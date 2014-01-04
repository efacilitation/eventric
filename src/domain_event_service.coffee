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
      if @_handlers[domainEvent.metaData.name]
        readModels = @_handlers[domainEvent.metaData.name][domainEvent.metaData.id]
        for readModel in readModels
          readModel._applyChanges domainEvent._changed

      # store the DomainEvent into local cache
      @_storeInCache domainEvent

      # now trigger the DomainEvent in multiple fashions
      @trigger 'DomainEvent', domainEvent
      @trigger domainEvent.metaData.name, domainEvent
      @trigger domainEvent.metaData.name + '/' + domainEvent.metaData.id, domainEvent
      @trigger domainEvent.metaData.name + ':' + domainEvent.name, domainEvent
      @trigger domainEvent.metaData.name + ':' + domainEvent.name + '/' + domainEvent.metaData.id, domainEvent

  _storeInCache: (domainEvent) ->
    @_cache.push domainEvent

# DomainEventService is a singelton!
domainEventService = new DomainEventService

module.exports = domainEventService
