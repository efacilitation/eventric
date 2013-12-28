moduleDefinition =
  AggregateRoot: './src/aggregate_root'
  Entity: './src/entity'
  EntityCollection: './src/entity_collection'

  ReadAggregateRoot: './src/read_aggregate_root'
  ReadEntity: './src/read_entity'

module.exports = (required) ->
  path = moduleDefinition[required] ? required

  try
    require path
  catch e
    console.log e
    throw e