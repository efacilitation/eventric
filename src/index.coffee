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


  boundedContext: (name) ->
    if !name
      throw new Error 'BoundedContexts must have a name'
    BoundedContext = @require 'BoundedContext'
    boundedContext = new BoundedContext name

    boundedContext.addDomainEventHandler 'DomainEvent', (domainEvent) =>
      if !@_domainEventHandlers[name]
        return

      eventName = domainEvent.aggregate.name + ':' + domainEvent.name
      if !@_domainEventHandlers[name][eventName]
        return

      for eventHandler in @_domainEventHandlers[name][eventName]
        eventHandler domainEvent

    boundedContext


  addDomainEventHandler: (boundedContextName, eventName, eventHandler) ->
    if !@_domainEventHandlers[boundedContextName]
      @_domainEventHandlers[boundedContextName] = {}

    if !@_domainEventHandlers[boundedContextName][eventName]
      @_domainEventHandlers[boundedContextName][eventName] = []

    @_domainEventHandlers[boundedContextName][eventName].push eventHandler
