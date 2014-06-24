eventric = require 'eventric'

_               = eventric.require 'HelperUnderscore'
Clone           = eventric.require 'HelperClone'
DomainEvent     = eventric.require 'DomainEvent'

class Aggregate

  constructor: (@_boundedContext, @_name, Root) ->
    @_domainEvents = []

    if !Root
      @_root = {}
    else
      @_root = new Root

    @_root.$emitDomainEvent = @emitDomainEvent


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
      id: @_generateUid()
      name: domainEventName
      aggregate:
        id: @id
        name: @_name
        context: @_boundedContext.name
      payload: new DomainEventClass domainEventPayload


  _handleDomainEvent: (domainEventName, domainEvent) ->
    if !@_root["handle#{domainEventName}"]
      console.log "Tried to handle the DomainEvent '#{domainEventName}' without a matching handle method"

    else
      @_root["handle#{domainEventName}"] domainEvent


  getDomainEvents: ->
    @_domainEvents


  applyDomainEvents: (domainEvents) ->
    @_applyDomainEvent domainEvent for domainEvent in domainEvents


  _applyDomainEvent: (domainEvent) ->
    @_handleDomainEvent domainEvent.name, domainEvent


  create: (props) ->
    new Promise (resolve, reject) =>
      @id = @_generateUid()

      if typeof @_root.create == 'function'
        try
          check = @_root.create props
          if check instanceof Promise
            check.then =>
              resolve()
            check.catch (err) =>
              reject err
          else
            resolve()
        catch e
          reject e

      else
        # automatically generate domainevent

        CreatedClass = class Created
        domainEvent = @_createDomainEvent "#{@_name}Created", CreatedClass
        @_domainEvents.push domainEvent

        @_root[key] = value for key, value of props
        resolve()


  command: (command) ->
    new Promise (resolve, reject) =>
      if command.name not of @_root
        err = new Error "Given commandName '#{command.name}' not found as method in the #{@_name} Aggregate Root"
        return reject err

      # make sure we have a params array
      command.params = [] if !command.params
      if not (command.params instanceof Array)
        command.params = [command.params]

      try
        check = @_root[command.name] command.params...
        if check instanceof Promise
          check.then =>
            resolve()
          check.catch (err) =>
            reject err
        else
          resolve()
      catch err
        reject err


  _generateUid: (separator) ->
    # http://stackoverflow.com/a/12223573
    S4 = ->
      (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1
    delim = separator or "-"
    S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4()


  toJSON: ->
    Clone @_root


module.exports = Aggregate
