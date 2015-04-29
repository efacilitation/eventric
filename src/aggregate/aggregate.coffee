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

    domainEvent = @_createDomainEvent domainEventName, DomainEventClass, domainEventPayload
    @_domainEvents.push domainEvent

    @_handleDomainEvent domainEventName, domainEvent
    @_eventric.log.debug "Created and Handled DomainEvent in Aggregate", domainEvent
    # TODO: do a rollback if something goes wrong inside the handle function


  _createDomainEvent: (domainEventName, DomainEventClass, domainEventPayload) ->
    payload = {}
    DomainEventClass.apply payload, [domainEventPayload]

    new @_eventric.DomainEvent
      id: @_eventric.generateUid()
      name: domainEventName
      aggregate:
        id: @id
        name: @_name
      context: @_context.name
      payload: payload


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
