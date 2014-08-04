eventric = require 'eventric'

_               = require './helper/underscore'
Clone           = require './helper/clone'
DomainEvent     = require './domain_event'

class Aggregate

  constructor: (@_context, @_name, Root) ->
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
      eventric.log.error err
      throw new Error err

    domainEvent = @_createDomainEvent domainEventName, DomainEventClass, domainEventPayload
    @_domainEvents.push domainEvent

    @_handleDomainEvent domainEventName, domainEvent
    eventric.log.debug "Created and Handled DomainEvent in Aggregate", domainEvent
    # TODO: do a rollback if something goes wrong inside the handle function


  _createDomainEvent: (domainEventName, DomainEventClass, domainEventPayload) ->
    new DomainEvent
      id: eventric.generateUid()
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
      eventric.log.debug "Tried to handle the DomainEvent '#{domainEventName}' without a matching handle method"


  getDomainEvents: ->
    @_domainEvents


  applyDomainEvents: (domainEvents) ->
    @_applyDomainEvent domainEvent for domainEvent in domainEvents


  _applyDomainEvent: (domainEvent) ->
    @_handleDomainEvent domainEvent.name, domainEvent


  create: ->
    params = arguments
    new Promise (resolve, reject) =>
      @id = eventric.generateUid()
      if typeof @root.create isnt 'function'
        err = "No create function on aggregate"
        eventric.log.error err
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


  toJSON: ->
    Clone @root


module.exports = Aggregate
