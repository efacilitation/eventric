moduleDefinition =
  AggregateRepository: './aggregate_repository'
  ReadAggregateRepository: './read_aggregate_repository'

  Aggregate: './aggregate'
  AggregateService: './aggregate_service'

  ReadAggregate: './read_aggregate'
  ReadAggregateEntity: './read_aggregate_entity'

  DomainEvent: './domain_event'
  DomainEventService: './domain_event_service'

  RemoteService: './remote_service'
  RemoteBoundedContext: './remote_bounded_context'

  HelperAsync: './helper/async'
  HelperEvents: './helper/events'
  HelperUnderscore: './helper/underscore'
  HelperObserve: './helper/observe'

  BoundedContext: './bounded_context'


_require = (required) ->
  path = moduleDefinition[required] ? required

  try
    require path
  catch e
    console.log e
    throw e

module.exports.require = _require


module.exports.boundedContext = ->
  BoundedContext = _require 'BoundedContext'
  new BoundedContext
