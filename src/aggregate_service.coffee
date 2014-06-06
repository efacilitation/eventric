eventric = require 'eventric'

_         = eventric.require 'HelperUnderscore'
async     = eventric.require 'HelperAsync'
Aggregate = eventric.require 'Aggregate'

class AggregateService

  constructor: (@_domainEventService, @_aggregateRepository) ->
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
      if typeof originalFunction isnt 'function' or originalFunctionName is 'constructor' or (originalFunctionName.indexOf '_') is 0
        # only check non-constructor functions for now
        continue

      @[originalFunctionName] = _proxy originalFunctionName, originalFunction


  create: ([aggregateName, props]..., callback) ->
    aggregateDefinition = @_aggregateRepository.getAggregateDefinition aggregateName
    if not aggregateDefinition
      err = new Error "Tried to create not registered Aggregate '#{aggregateName}'"
      callback err, null
      return

    # create Aggregate
    aggregate = new Aggregate aggregateName, aggregateDefinition, props

    @_aggregateRepository.findById aggregateName, aggregate.id, (err, aggregateCheck) =>
      return callback err, null if err

      # if for some reason we try to create an already existing aggregateId, skip now
      if aggregateCheck
        err = new Error "Tried to create already existing aggregateId #{aggregate.id}"
        callback err, null
        return

      @_generateSaveAndTriggerDomainEvent 'create', aggregate, callback


  command: ([aggregateName, aggregateId, commandName, params]..., callback) ->
    # get the aggregate from the AggregateRepository
    @_aggregateRepository.findById aggregateName, aggregateId, (err, aggregate) =>
      return callback err, null if err

      if not aggregate
        err = new Error "No #{aggregateName} Aggregate with given aggregateId #{aggregateId} found"
        callback err, null
        return

      if commandName not of aggregate.root
        err = new Error "Given commandName '#{commandName}' not found as method in the #{aggregateName} Aggregate Root"
        callback err, null
        return

      # make sure we have a params array
      if not (params instanceof Array)
        params = [params]

      # TODO: Should be ok as long as aggregates arent async
      errorCallbackCalled = false
      errorCallback = (err) =>
        errorCallbackCalled = true
        callback err

      # EXECUTING
      aggregate.root[commandName] params..., errorCallback

      return if errorCallbackCalled

      @_generateSaveAndTriggerDomainEvent commandName, aggregate, callback


  _generateSaveAndTriggerDomainEvent: (commandName, aggregate, callback) ->
    # generate the DomainEvent
    aggregate.generateDomainEvent commandName

    # get the DomainEvents and hand them over to DomainEventService
    domainEvents = aggregate.getDomainEvents()
    @_domainEventService.saveAndTrigger domainEvents, (err) =>
      return callback err, null if err

      aggregate.clearChanges()

      # return the aggregateId
      callback? null, aggregate.id


module.exports = AggregateService
