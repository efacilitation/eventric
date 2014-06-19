eventric = require 'eventric'

_          = eventric.require 'HelperUnderscore'
async      = eventric.require 'HelperAsync'
Repository = eventric.require 'Repository'
Aggregate  = eventric.require 'Aggregate'

class AggregateService
  _AggregateRootClasses: {}

  initialize: (@_eventStore, @_domainEventService, @_boundedContext ) ->
    # proxy & queue public api
    _queue = async.queue (payload, callback) =>
      payload.originalFunction.call @, payload.arguments...
      .then (aggregateId) ->
        payload.resolve aggregateId
        callback()

      .catch (error) ->
        payload.reject error
        callback error

    , 1

    _proxy = (_originalFunctionName, _originalFunction) -> ->
      originalArguments = arguments
      new Promise (resolve, reject) ->
        _queue.push
          originalFunction: _originalFunction
          arguments: originalArguments
          resolve: resolve
          reject: reject

    for originalFunctionName, originalFunction of @
      # proxy only command and create
      if originalFunctionName is 'command' or originalFunctionName is 'create'
        @[originalFunctionName] = _proxy originalFunctionName, originalFunction


  create: (params) ->
    new Promise (resolve, reject) =>
      aggregateName  = params.name
      aggregateProps = params.props

      AggregateRoot = @getAggregateRoot aggregateName
      if not AggregateRoot
        err = new Error "Tried to create not registered AggregateDefinition '#{aggregateName}'"
        return reject err

      # create Aggregate
      aggregate = new Aggregate @_boundedContext, aggregateName, AggregateRoot
      aggregate.create aggregateProps

      .then =>
        @_saveAndTriggerDomainEvents aggregate, resolve, reject

      .catch (err) =>
        reject err


  command: (params) ->
    new Promise (resolve, reject) =>
      aggregateId   = params.id
      aggregateName = params.name
      methodName    = params.methodName
      methodParams  = params.methodParams

      AggregateRoot = @getAggregateRoot aggregateName
      if not AggregateRoot
        err = new Error "Tried to command not registered AggregateRoot '#{aggregateName}'"
        return reject err

      repository = new Repository
        aggregateName: aggregateName
        AggregateRoot: AggregateRoot
        boundedContext: @_boundedContext
        eventStore: @_eventStore

      # get the aggregate from the AggregateRepository
      repository.findById aggregateId, (err, aggregate) =>
        return reject err if err

        if not aggregate
          err = new Error "No #{aggregateName} Aggregate with given aggregateId #{aggregateId} found"
          return reject err

        if !methodParams
          methodParams = []

        # EXECUTING
        aggregate.command
          name: methodName
          params: methodParams

        .then =>
          @_saveAndTriggerDomainEvents aggregate, resolve, reject

        .catch (err) =>
          reject err


  _saveAndTriggerDomainEvents: (aggregate, resolve, reject) ->
    # get the DomainEvents and hand them over to DomainEventService
    domainEvents = aggregate.getDomainEvents()
    @_domainEventService.saveAndTrigger domainEvents, (err) =>
      return reject err if err

      # return the aggregateId
      resolve aggregate.id


  registerAggregateRoot: (aggregateName, AggregateRoot) ->
    @_AggregateRootClasses[aggregateName] = AggregateRoot


  getAggregateRoot: (aggregateName) ->
    @_AggregateRootClasses[aggregateName]


module.exports = AggregateService
