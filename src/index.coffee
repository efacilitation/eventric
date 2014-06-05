moduleDefinition =
  AggregateRepository: './aggregate_repository'
  ReadAggregateRepository: './read_aggregate_repository'

  AggregateService: './aggregate_service'
  AggregateRoot: './aggregate_root'
  AggregateEntity: './aggregate_entity'

  ReadAggregateRoot: './read_aggregate_root'
  ReadAggregateEntity: './read_aggregate_entity'

  DomainEvent: './domain_event'
  DomainEventService: './domain_event_service'

  RemoteService: './remote_service'
  RemoteBoundedContext: './remote_bounded_context'

  MixinSetGet: './mixin_setget'
  MixinEvents: './mixin_events'

  HelperUnderscore: './helper/underscore'
  HelperAsync: './helper/async'
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
