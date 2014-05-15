eventric = require 'eventric'
_ = eventric 'HelperUnderscore'

class ReadMix

  loadFromEvents: (domainEvents) ->
    return unless @domainEventHandlers

    for domainEvent in domainEvents
      if @domainEventHandlers["#{domainEvent.aggregate.name}:#{domainEvent.name}"]
        @domainEventHandlers["#{domainEvent.aggregate.name}:#{domainEvent.name}"] domainEvent, domainEvent.aggregate?.changed?

  loadFromJSON: (json) ->
    @_props = json

  _set: (key, value) ->
    @_props ?= {}

    @_props[key] = value

  _get: (key) ->
    @_props ?= {}

    @_props[key]

  _isset: (key) ->
    @_props ?= {}

    key of @_props

  toJSON: ->
    @_props ?= {}

    _.clone @_props

module.exports = ReadMix
