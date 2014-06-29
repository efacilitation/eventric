# polyfill promises
require './helper/promise'

moduleDefinition =
  BoundedContext: './bounded_context'

  Aggregate: './aggregate'
  AggregateService: './aggregate_service'

  ReadAggregate: './read_aggregate'
  ReadAggregateEntity: './read_aggregate_entity'

  DomainEvent: './domain_event'
  DomainEventService: './domain_event_service'

  RemoteService: './remote_service'
  RemoteBoundedContext: './remote_bounded_context'

  Repository: './repository'

  HelperAsync: './helper/async'
  HelperEvents: './helper/events'
  HelperUnderscore: './helper/underscore'
  HelperClone: './helper/clone'


module.exports =
  _params: {}
  _domainEventHandlers: {}

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
  * @param {String} boundedContextName Name of the BoundedContext
  * @param {String} eventName Name of the Event
  * @param {Function} eventHandler Function which handles the DomainEvent
  ###
  addDomainEventHandler: (boundedContextName, eventName, eventHandler) ->
    if !@_domainEventHandlers[boundedContextName]
      @_domainEventHandlers[boundedContextName] = {}

    if !@_domainEventHandlers[boundedContextName][eventName]
      @_domainEventHandlers[boundedContextName][eventName] = []

    @_domainEventHandlers[boundedContextName][eventName].push eventHandler


  ###*
  *
  * @description
  *
  * Use as: example = eventric.boundedContext(params)
  *
  * Get a new [[BoundedContext]] instance.
  *
  * @param {Object}
  * - `name` Name for the BoundedContext
  * - `store` An Instance of a eventric StoreAdapter (optional if configured globally)
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
      if not @_domainEventHandlers[boundedContext.name]
        return

      boundedContextHandler = @_domainEventHandlers[boundedContext.name]
      if not boundedContextHandler[domainEvent.name] and not boundedContextHandler.all
        return

      eventHandlers = boundedContextHandler[domainEvent.name] ? boundedContextHandler.all
      for eventHandler in eventHandlers
        eventHandler domainEvent
