moduleDefinition =
  AggregateRepository: './src/aggregate_repository'
  AggregateRoot: './src/aggregate_root'
  AggregateEntity: './src/aggregate_entity'
  AggregateEntityCollection: './src/aggregate_entity_collection'

  ReadAggregateRepository: './src/read_aggregate_repository'
  ReadAggregateRoot: './src/read_aggregate_root'
  ReadAggregateEntity: './src/read_aggregate_entity'

  ReadMix: './src/read_mix'
  ReadMixRepository: './src/read_mix_repository'

  CommandService: './src/command_service'
  DomainEventService: './src/domain_event_service'
  SocketService: './src/socket_service'

  Repository: './src/repository'
  RepositoryInMemoryAdapter: './src/repository_adapters/inmemory_adapter'
  RepositorySocketIOAdapter: './src/repository_adapters/socketio_adapter'

  EventStoreInMemory: './src/event_store/inmemory_store'

module.exports = (required) ->
  path = moduleDefinition[required] ? required

  try
    require path
  catch e
    console.log e
    throw e