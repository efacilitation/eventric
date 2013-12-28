moduleDefinition =
  AggregateRoot: './src/aggregate_root'
  AggregateEntity: './src/aggregate_entity'
  AggregateEntityCollection: './src/aggregate_entity_collection'

  ReadAggregateRoot: './src/read_aggregate_root'
  ReadAggregateEntity: './src/read_aggregate_entity'

  DomainEventService: './src/domain_event_service'
  SocketService: './src/socket_service'

module.exports = (required) ->
  path = moduleDefinition[required] ? required

  try
    require path
  catch e
    console.log e
    throw e