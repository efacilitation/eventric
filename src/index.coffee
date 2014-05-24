moduleDefinition =
  AggregateRepository: './aggregate_repository'
  ReadAggregateRepository: './read_aggregate_repository'

  AggregateRoot: './aggregate_root'
  AggregateEntity: './aggregate_entity'
  AggregateEntityCollection: './aggregate_entity_collection'

  ReadAggregateRoot: './read_aggregate_root'
  ReadAggregateEntity: './read_aggregate_entity'

  ReadMix: './read_mix'
  ReadMixRepository: './read_mix_repository'

  CommandService: './command_service'
  DomainEventService: './domain_event_service'

  RemoteService: './remote_service'
  RemoteBoundedContext: './remote_bounded_context'
  RemoteCommandService: './remote_command_service'
  RemoteRepositoryService: './remote_repository_service'

  MixinRegisterAndGetClass: './mixin_registerandgetclass'
  MixinSetGet: './mixin_setget'
  MixinEvents: './mixin_events'

  HelperUnderscore: './helper/underscore'
  HelperAsync: './helper/async'
  HelperObserve: './helper/observe'

  BoundedContext: './bounded_context'
  BoundedContextService: './bounded_context_service'

  DomainEvent: './domain_event'


module.exports.require = (required) ->
  path = moduleDefinition[required] ? required

  try
    require path
  catch e
    console.log e
    throw e
