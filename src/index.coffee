moduleDefinition =
  AggregateRepository: './aggregate_repository'
  AggregateRoot: './aggregate_root'
  AggregateEntity: './aggregate_entity'
  AggregateEntityCollection: './aggregate_entity_collection'

  ReadAggregateRepository: './read_aggregate_repository'
  ReadAggregateRoot: './read_aggregate_root'
  ReadAggregateEntity: './read_aggregate_entity'

  ReadMix: './read_mix'
  ReadMixRepository: './read_mix_repository'

  CommandService: './command_service'
  DomainEventService: './domain_event_service'
  SocketService: './socket_service'

  Repository: './repository'

  InMemoryEventStore: './event_store/inmemory_event_store'
  MongoDBEventStore: './event_store/mongodb_event_store'

module.exports = (required) ->
  path = moduleDefinition[required] ? required

  try
    require path
  catch e
    console.log e
    throw e