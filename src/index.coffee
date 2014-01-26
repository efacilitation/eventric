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
  RemoteCommandService: './remote_command_service'
  RemoteRepositoryService: './remote_repository_service'

  MixinRegisterAndGetClass: './mixin_registerandgetclass'
  MixinSnapshot: './mixin_snapshot'
  MixinSetGet: './mixin_setget'

  # should be seperate modules
  SocketIORemoteService: './remote_service/socketio_remote_service'
  MongoDBEventStore: './event_store/mongodb_event_store'

module.exports = (required) ->
  path = moduleDefinition[required] ? required

  try
    require path
  catch e
    console.log e
    throw e