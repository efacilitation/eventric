###*
* @name Aggregate
* @module Aggregate
* @description
*
* Aggregates live inside a Context and give you basically transactional boundaries
* for your Behaviors and DomainEvents.
###
class Aggregate

  constructor: (@_context, @_eventric, @_name, Root) ->
    @_domainEvents = []

    if !Root
      @root = {}
    else
      @root = new Root

    @root.$emitDomainEvent = @emitDomainEvent


  ###*
  * @name emitDomainEvent
  * @module Aggregate
  * @description Emit DomainEvent
  *
  * @param {String} domainEventName Name of the DomainEvent
  * @param {Object} domainEventPayload Object containing the payload of the DomainEvent
  ###
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
    new @_eventric.DomainEvent
      id: @_eventric.generateUid()
      name: domainEventName
      aggregate:
        id: @id
        name: @_name
      context: @_context.name
      payload: new DomainEventClass domainEventPayload


  _handleDomainEvent: (domainEventName, domainEvent) ->
    if @root["handle#{domainEventName}"]
      @root["handle#{domainEventName}"] domainEvent, ->

    else
      @_eventric.log.debug "Tried to handle the DomainEvent '#{domainEventName}' without a matching handle method"

  ###*
  * @name getDomainEvents
  * @module Aggregate
  * @description Get all emitted DomainEvents
  ###
  getDomainEvents: =>
    @_domainEvents


  ###*
  * @name applyDomainEvents
  * @module Context
  * @description Apply DomainEvents to the Aggregate
  *
  * @param {Array} domainEvents Array containing DomainEvents
  ###
  applyDomainEvents: (domainEvents) ->
    @_applyDomainEvent domainEvent for domainEvent in domainEvents


  _applyDomainEvent: (domainEvent) ->
    @_handleDomainEvent domainEvent.name, domainEvent


  ###*
  * @name create
  * @module Aggregate
  * @description Calls the create Function on your AggregateDefinition
  ###
  create: =>
    params = arguments
    new Promise (resolve, reject) =>
      @id = @_eventric.generateUid()
      if typeof @root.create isnt 'function'
        err = "No create function on aggregate"
        @_eventric.log.error err
        throw new Error err

      try
        check = @root.create params..., (err) =>
          if err
            reject err
          else
            resolve @

        if check instanceof Promise
          check.then =>
            resolve @
          check.catch (err) =>
            reject err

      catch e
        reject e


module.exports = Aggregate
