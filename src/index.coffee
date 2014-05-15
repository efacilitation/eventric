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
  MixinSnapshot: './mixin_snapshot'
  MixinSetGet: './mixin_setget'
  MixinEvents: './mixin_events'

  HelperUnderscore: './helper_underscore'
  HelperAsync: './helper_async'

  BoundedContext: './bounded_context'
  BoundedContextService: './bounded_context_service'


module.exports = (required) ->
  path = moduleDefinition[required] ? required

  try
    require path
  catch e
    console.log e
    throw e
