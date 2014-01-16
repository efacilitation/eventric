eventric = require 'eventric'

DomainEventService = eventric 'DomainEventService'

class CommandService

  constructor: (@_domainEventService, @_aggregateRepository) ->

  createAggregate: ([aggregateName, params]..., callback) ->
    AggregateClass = @_aggregateRepository.getClass aggregateName
    if not AggregateClass
      err = new Error "Tried to create not registered Aggregate '#{aggregateName}'"
      callback err, null

    else
      # create Aggregate
      aggregate = new AggregateClass
      aggregate.create()

      # apply given params
      aggregate[key] = value for key, value of params

      @_aggregateRepository.findById aggregateName, aggregate.id, (err, aggregateCheck) =>
        # if for some reason we try to create an already existing aggregateId, skip now
        if aggregateCheck
          err = new Error "Tried to create already existiting aggregateId #{aggregate.id}"
          callback err, null
          return

        @_handle 'create', aggregate, callback

  commandAggregate: ([aggregateName, aggregateId, commandName, params]..., callback) ->
    # get the aggregate from the AggregateRepository
    @_aggregateRepository.findById aggregateName, aggregateId, (err, aggregate) =>
      if err
        callback err, null

      else if commandName not of aggregate
        err = new Error "Given commandName '#{commandName}' not found as method in the aggregate", aggregate
        callback err, null

      else
        aggregate[commandName] params
        @_handle commandName, aggregate, callback


  _handle: (commandName, aggregate, callback) ->
    # generate the DomainEvent
    aggregate.generateDomainEvent commandName

    # get the DomainEvents and hand them over to DomainEventService
    domainEvents = aggregate.getDomainEvents()
    @_domainEventService.saveAndTrigger domainEvents
    aggregate.clearChanges()

    # return the aggregateId
    callback null, aggregate.id


module.exports = CommandService