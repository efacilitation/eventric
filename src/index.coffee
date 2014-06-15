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
  HelperObjectDiff: './helper/diff2'


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


  boundedContext: (params = {}) ->
    if !params.name
      return new Error 'BoundedContexts must have a name'

    if params.store
      store = params.store
    else if @_params.store
      store = @_params.store
    else
      return new Error 'Missing Store'

    BoundedContext = @require 'BoundedContext'
    boundedContext = new BoundedContext
    boundedContext.initialize params.name, store
    boundedContext


  addDomainEventHandler: (boundedContextName, eventName, eventHandler) ->
    if !@_domainEventHandlers[boundedContextName]
      @_domainEventHandlers[boundedContextName] = []

    @_domainEventHandlers[boundedContextName].push
      name: eventName
      handler: eventHandler
