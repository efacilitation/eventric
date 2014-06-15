# polyfill promises
require './helper/promise'

moduleDefinition =
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

  BoundedContext: './bounded_context'


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


  boundedContext: (params) ->
    new Promise (resolve, reject) =>
      if !params.name
        error = new Error 'BoundedContexts must have a name'
        reject error

      store = params.store ? null
      if !params.store
        store = @_params.store ? null

      BoundedContext = @require 'BoundedContext'
      if !store
        # TODO: for now we require and initialize 'event-store-mongodb'by default, should reject maybe?
        store = require 'eventric-store-mongodb'
        store.initialize =>
          boundedContext = new BoundedContext
          boundedContext.initialize params.name, store
          resolve boundedContext

      else
        boundedContext = new BoundedContext
        boundedContext.initialize params.name, store
        resolve boundedContext


  addDomainEventHandler: (boundedContextName, eventName, eventHandler) ->
    if !@_domainEventHandlers[boundedContextName]
      @_domainEventHandlers[boundedContextName] = []

    @_domainEventHandlers[boundedContextName].push
      name: eventName
      handler: eventHandler
