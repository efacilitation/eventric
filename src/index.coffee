# polyfill promises
require './helper/promise'

moduleDefinition =
  BoundedContext: './bounded_context'

  Aggregate: './aggregate'
  AggregateService: './aggregate_service'

  DomainEvent: './domain_event'
  DomainEventService: './domain_event_service'

  EventBus: './event_bus'
  Repository: './repository'

  RemoteService: './remote_service'
  RemoteBoundedContext: './remote_bounded_context'

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
  * @description Global DomainEvent Handlers
  *
  * @param {String} boundedContextName Name of the BoundedContext or 'all'
  * @param {String} eventName Name of the Event or 'all'
  * @param {Function} eventHandler Function which handles the DomainEvent
  ###
  addDomainEventHandler: ([boundedContextName, eventName]..., eventHandler) ->
    boundedContextName ?= 'all'
    eventName ?= 'all'

    if boundedContextName is 'all' and eventName is 'all'
      @_domainEventHandlersAll.push eventHandler
    else
      if !@_domainEventHandlers[boundedContextName]
        @_domainEventHandlers[boundedContextName] = {}

      if !@_domainEventHandlers[boundedContextName][eventName]
        @_domainEventHandlers[boundedContextName][eventName] = []

      @_domainEventHandlers[boundedContextName][eventName].push eventHandler


  ###*
  *
  * @description Get a new BoundedContext instance.
  *
  * @param {String} name Name of the BoundedContext
  ###
  boundedContext: (name) ->
    if !name
      throw new Error 'BoundedContexts must have a name'
    BoundedContext = @require 'BoundedContext'
    boundedContext = new BoundedContext name

    @_delegateAllDomainEventsToGlobalHandlers boundedContext

    boundedContext


  _delegateAllDomainEventsToGlobalHandlers: (boundedContext) ->
    boundedContext.addDomainEventHandler 'DomainEvent', (domainEvent) =>
      eventHandlers = [].concat (@_domainEventHandlers[boundedContext.name]?[domainEvent.name] ? []),
                                (@_domainEventHandlers[boundedContext.name]?.all ? []),
                                (@_domainEventHandlersAll ? [])
      for eventHandler in eventHandlers
        eventHandler domainEvent
