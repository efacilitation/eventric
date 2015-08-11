logger = require 'eventric/logger'

class Aggregate

  constructor: (@_context, @_name, AggregateClass) ->
    @_domainEvents = []
    @instance = new AggregateClass
    @instance.$emitDomainEvent = @emitDomainEvent


  emitDomainEvent: (domainEventName, domainEventPayload) =>
    aggregate =
      id: @id
      name: @_name

    domainEvent = @_context.createDomainEvent domainEventName, domainEventPayload, aggregate
    @_domainEvents.push domainEvent

    @_handleDomainEvent domainEventName, domainEvent
    logger.debug "Created and Handled DomainEvent in Aggregate", domainEvent


  _handleDomainEvent: (domainEventName, domainEvent) ->
    if @instance["handle#{domainEventName}"]
      @instance["handle#{domainEventName}"] domainEvent


  getDomainEvents: =>
    @_domainEvents


  applyDomainEvents: (domainEvents) ->
    @_applyDomainEvent domainEvent for domainEvent in domainEvents


  _applyDomainEvent: (domainEvent) ->
    @_handleDomainEvent domainEvent.name, domainEvent


module.exports = Aggregate
