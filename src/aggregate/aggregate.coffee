class Aggregate

  constructor: (@_context, @_eventric, @_name, AggregateClass) ->
    @_domainEvents = []
    @instance = new AggregateClass
    @instance.$emitDomainEvent = @emitDomainEvent


  emitDomainEvent: (domainEventName, domainEventPayload) =>
    DomainEventClass = @_context.getDomainEvent domainEventName
    if !DomainEventClass
      throw new Error "Tried to emitDomainEvent '#{domainEventName}' which is not defined"

    aggregate =
      id: @id
      name: @_name
    domainEvent = @_context.createDomainEvent domainEventName, DomainEventClass, domainEventPayload, aggregate
    @_domainEvents.push domainEvent

    @_handleDomainEvent domainEventName, domainEvent
    @_eventric.log.debug "Created and Handled DomainEvent in Aggregate", domainEvent


  _handleDomainEvent: (domainEventName, domainEvent) ->
    if @instance["handle#{domainEventName}"]
      @instance["handle#{domainEventName}"] domainEvent
    else
      @_eventric.log.debug "Tried to handle the DomainEvent '#{domainEventName}' without a matching handle method"


  getDomainEvents: =>
    @_domainEvents


  applyDomainEvents: (domainEvents) ->
    @_applyDomainEvent domainEvent for domainEvent in domainEvents


  _applyDomainEvent: (domainEvent) ->
    @_handleDomainEvent domainEvent.name, domainEvent


module.exports = Aggregate
