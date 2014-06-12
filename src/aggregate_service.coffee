eventric = require 'eventric'

_          = eventric.require 'HelperUnderscore'
async      = eventric.require 'HelperAsync'
Repository = eventric.require 'Repository'
Aggregate  = eventric.require 'Aggregate'

class AggregateService
  _aggregateDefinitions: {}

  constructor: (@_eventStore, @_domainEventService) ->
    # proxy & queue public api
    _queue = async.queue (payload, next) =>
      payload.originalFunction.call @, payload.arguments..., next
    , 1

    _proxy = (_originalFunctionName, _originalFunction) -> ->
      originalCallback = arguments[arguments.length - 1]
      delete arguments[arguments.length - 1]
      _queue.push
        originalFunction: _originalFunction
        arguments: arguments
      , originalCallback

    for originalFunctionName, originalFunction of @
      # proxy only command and create
      if originalFunctionName is 'command' or originalFunctionName is 'create'
        @[originalFunctionName] = _proxy originalFunctionName, originalFunction


  create: ([aggregateName, props]..., callback) ->
    aggregateDefinition = @getAggregateDefinition aggregateName
    if not aggregateDefinition
      err = new Error "Tried to create not registered AggregateDefinition '#{aggregateName}'"
      callback err, null
      return

    # create Aggregate
    aggregate = new Aggregate aggregateName, aggregateDefinition
    aggregate.create props

    @_generateSaveAndTriggerDomainEvent 'create', aggregate, callback


  command: ([aggregateName, aggregateId, commandName, params]..., callback) ->
    aggregateDefinition = @getAggregateDefinition aggregateName
    if not aggregateDefinition
      err = new Error "Tried to command not registered AggregateDefinition '#{aggregateName}'"
      callback err, null
      return

    repository = new Repository
      aggregateName: aggregateName
      aggregateDefinition: aggregateDefinition
      eventStore: @_eventStore

    # get the aggregate from the AggregateRepository
    repository.findById aggregateId, (err, aggregate) =>
      return callback err, null if err

      if not aggregate
        err = new Error "No #{aggregateName} Aggregate with given aggregateId #{aggregateId} found"
        callback err, null
        return

      # TODO: Should be ok as long as aggregates arent async
      errorCallbackCalled = false
      errorCallback = (err) =>
        errorCallbackCalled = true
        callback err

      if !params
        params = []

      # EXECUTING
      aggregate.command
        name: commandName
        params: params
      , errorCallback

      return if errorCallbackCalled

      @_generateSaveAndTriggerDomainEvent commandName, aggregate, callback


  _generateSaveAndTriggerDomainEvent: (commandName, aggregate, callback) ->
    # generate the DomainEvent
    aggregate.generateDomainEvent commandName

    # get the DomainEvents and hand them over to DomainEventService
    domainEvents = aggregate.getDomainEvents()
    @_domainEventService.saveAndTrigger domainEvents, (err) =>
      return callback err, null if err

      # return the aggregateId
      callback? null, aggregate.id


  registerAggregateDefinition: (aggregateName, aggregateDefinition) ->
    @_aggregateDefinitions[aggregateName] = aggregateDefinition


  getAggregateDefinition: (aggregateName) ->
    @_aggregateDefinitions[aggregateName]


module.exports = AggregateService
