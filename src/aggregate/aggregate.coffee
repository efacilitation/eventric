DomainEvent = require 'eventric/domain_event'

class Aggregate

  constructor: (@_context, @_name, AggregateClass) ->
    @_newDomainEvents = []
    @instance = new AggregateClass
    @instance.$emitDomainEvent = @emitDomainEvent


  setId: (@id) ->
    @instance.$id = @id


  emitDomainEvent: (domainEventName, domainEventPayload) =>
    aggregate =
      id: @id
      name: @_name

    domainEvent = @_createDomainEvent domainEventName, domainEventPayload, aggregate
    @_newDomainEvents.push domainEvent

    @_handleDomainEvent domainEventName, domainEvent


  _createDomainEvent: (domainEventName, domainEventConstructorParams, aggregate) ->
    DomainEventPayloadConstructor = @_context.getDomainEventPayloadConstructor domainEventName

    if !DomainEventPayloadConstructor
      throw new Error "Tried to create domain event '#{domainEventName}' which is not defined"

    payload = {}
    DomainEventPayloadConstructor.apply payload, [domainEventConstructorParams]

    new DomainEvent
      name: domainEventName
      aggregate: aggregate
      context: @_context.name
      payload: payload


  _handleDomainEvent: (domainEventName, domainEvent) ->
    if @instance["handle#{domainEventName}"]
      @instance["handle#{domainEventName}"] domainEvent


  getNewDomainEvents: ->
    @_newDomainEvents


  applyDomainEvents: (domainEvents) ->
    @_applyDomainEvent domainEvent for domainEvent in domainEvents


  _applyDomainEvent: (domainEvent) ->
    @_handleDomainEvent domainEvent.name, domainEvent


module.exports = Aggregate
