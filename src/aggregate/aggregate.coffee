class Aggregate

  constructor: (@_context, @_eventric, @_name, Root) ->
    @_domainEvents = []

    if !Root
      @root = {}
    else
      @root = new Root

    @root.$emitDomainEvent = @emitDomainEvent


  emitDomainEvent: (domainEventName, domainEventPayload) =>
    DomainEventClass = @_context.getDomainEvent domainEventName
    if !DomainEventClass
      err = "Tried to emitDomainEvent '#{domainEventName}' which is not defined"
      @_eventric.log.error err
      throw new Error err

    aggregate =
      id: @id
      name: @_name
    domainEvent = @_context.createDomainEvent domainEventName, DomainEventClass, domainEventPayload, aggregate
    @_domainEvents.push domainEvent

    @_handleDomainEvent domainEventName, domainEvent
    @_eventric.log.debug "Created and Handled DomainEvent in Aggregate", domainEvent
    # TODO: do a rollback if something goes wrong inside the handle function


  _handleDomainEvent: (domainEventName, domainEvent) ->
    if @root["handle#{domainEventName}"]
      @root["handle#{domainEventName}"] domainEvent, ->

    else
      @_eventric.log.debug "Tried to handle the DomainEvent '#{domainEventName}' without a matching handle method"


  getDomainEvents: =>
    @_domainEvents


  applyDomainEvents: (domainEvents) ->
    @_applyDomainEvent domainEvent for domainEvent in domainEvents


  _applyDomainEvent: (domainEvent) ->
    @_handleDomainEvent domainEvent.name, domainEvent


module.exports = Aggregate
