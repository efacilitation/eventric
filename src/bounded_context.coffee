class BoundedContext

  constructor: (options) ->
    @name                    = options.name
    @commandService          = options.commandService
    @readAggregateRepository = options.readAggregateRepository


  command: (command, aggregateId, params) ->
    [aggregateName, methodName] = command.split ':'
    @commandService.commandAggregate aggregateName, aggregateId, methodName, params

module.exports = BoundedContext