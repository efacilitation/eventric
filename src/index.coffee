# polyfill promises
require './helper/promise'

moduleDefinition =
  MicroContext: './micro_context'
  Aggregate: './aggregate'
  DomainEvent: './domain_event'
  EventBus: './event_bus'
  Repository: './repository'

  RemoteService: './remote_service'
  RemoteMicroContext: './remote_micro_context'

  HelperAsync: './helper/async'
  HelperEvents: './helper/events'
  HelperUnderscore: './helper/underscore'
  HelperClone: './helper/clone'


module.exports =
  _params: {}
  _domainEventHandlers: {}
  _domainEventHandlersAll: []

  require: (required) ->
    path = moduleDefinition[required] ? required

    try
      require path
    catch e
      console.log e
      throw e


  set: (key, value) ->
    @_params[key] = value


  get: (key) ->
    @_params[key]


  ###*
  *
  * @description Get a new MicroContext instance.
  *
  * @param {String} name Name of the MicroContext
  ###
  microContext: (name) ->
    if !name
      throw new Error 'MicroContexts must have a name'
    MicroContext = @require 'MicroContext'
    microContext = new MicroContext name

    @_delegateAllDomainEventsToGlobalHandlers microContext

    microContext


  context: ->
    @microContext arguments...


  _delegateAllDomainEventsToGlobalHandlers: (microContext) ->
    microContext.addDomainEventHandler 'DomainEvent', (domainEvent) =>
      eventHandlers = @getDomainEventHandlers microContext.name, domainEvent.name
      for eventHandler in eventHandlers
        eventHandler domainEvent


  ###*
  *
  * @description Global DomainEvent Handlers
  *
  * @param {String} microContextName Name of the MicroContext or 'all'
  * @param {String} eventName Name of the Event or 'all'
  * @param {Function} eventHandler Function which handles the DomainEvent
  ###
  addDomainEventHandler: ([microContextName, eventName]..., eventHandler) ->
    microContextName ?= 'all'
    eventName ?= 'all'

    if microContextName is 'all' and eventName is 'all'
      @_domainEventHandlersAll.push eventHandler
    else
      if !@_domainEventHandlers[microContextName]
        @_domainEventHandlers[microContextName] = {}

      if !@_domainEventHandlers[microContextName][eventName]
        @_domainEventHandlers[microContextName][eventName] = []

      @_domainEventHandlers[microContextName][eventName].push eventHandler


  getDomainEventHandlers: (microContextName, domainEventName) ->
    [].concat (@_domainEventHandlers[microContextName]?[domainEventName] ? []),
              (@_domainEventHandlers[microContextName]?.all ? []),
              (@_domainEventHandlersAll ? [])


  generateUid: (separator) ->
    # http://stackoverflow.com/a/12223573
    S4 = ->
      (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1
    delim = separator or "-"
    S4() + S4() + delim + S4() + delim + S4() + delim + S4() + delim + S4() + S4() + S4()
