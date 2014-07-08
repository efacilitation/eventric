eventric = require 'eventric'

_               = eventric.require 'HelperUnderscore'
Clone           = eventric.require 'HelperClone'
DomainEvent     = eventric.require 'DomainEvent'

class Aggregate

  constructor: (@_boundedContext, @_name, Root) ->
    @_domainEvents = []

    if !Root
      @root = {}
    else
      @root = new Root

    @root.$emitDomainEvent = @emitDomainEvent


  emitDomainEvent: (domainEventName, domainEventPayload) =>
    DomainEventClass = @_boundedContext.getDomainEvent domainEventName
    if !DomainEventClass
      throw new Error "Tried to emitDomainEvent '#{domainEventName}' which is not defined"

    domainEvent = @_createDomainEvent domainEventName, DomainEventClass, domainEventPayload
    @_domainEvents.push domainEvent

    @_handleDomainEvent domainEventName, domainEvent
    # TODO: do a rollback if something goes wrong inside the handle function


  _createDomainEvent: (domainEventName, DomainEventClass, domainEventPayload) ->
    new DomainEvent
      id: eventric.generateUid()
      name: domainEventName
      aggregate:
        id: @id
        name: @_name
      boundedContext: @_boundedContext.name
      payload: new DomainEventClass domainEventPayload


  _handleDomainEvent: (domainEventName, domainEvent) ->
    if @root["handle#{domainEventName}"]
      @root["handle#{domainEventName}"] domainEvent

    else
      err = new Error "Tried to handle the DomainEvent '#{domainEventName}' without a matching handle method"


  getDomainEvents: ->
    @_domainEvents


  applyDomainEvents: (domainEvents) ->
    @_applyDomainEvent domainEvent for domainEvent in domainEvents


  _applyDomainEvent: (domainEvent) ->
    @_handleDomainEvent domainEvent.name, domainEvent


  create: (props) ->
    new Promise (resolve, reject) =>
      @id = eventric.generateUid()

      if typeof @root.create == 'function'
        try
          check = @root.create props
          if check instanceof Promise
            check.then =>
              resolve @
            check.catch (err) =>
              reject err
          else
            resolve @
        catch e
          reject e

      else
        @emitDomainEvent "#{@_name}Created", props
        resolve @


  toJSON: ->
    Clone @root


module.exports = Aggregate
