Repository = require('eventric')('Repository')

class ReadAggregateRepository extends Repository

  constructor: (@_adapter, @_ReadAggregateClass) ->

  findById: (id) ->
    # create and return a ReadAggregate instance with the data-row found
    @_createReadAggregateInstance @_findDomainEventsByAggregateId id

  findByIds: (ids) ->
    # call finyById for every given Id
    @findById id for id in ids

  find: (query, projection) ->
    # find aggregate data based on query and projection
    results = @_findAggregateData query, projection

    # create and return a ReadAggregate instance for every data-row found
    @_createReadAggregateInstance data for data in results

  findIds: (query) ->
    # only return aggregateIds
    projection =
      _id: 0
      aggregateId: 1

    # ask the adapter to find the ids
    results = @_findAggregateData query, projection

    # convert to array of ids and return
    object.id for object in results


  _findAggregateDataById: (id) ->
    # ask the adapter to findById
    @_adapter.findById id

  _findAggregateData: (query, projection) ->
    # ask the adapter to find based on query and projection
    @_adapter.find query, projection


  _createReadAggregateInstance: (data) ->
    # create and return a ReadAggregate instance with the given data
    new @_ReadAggregateClass data

module.exports = ReadAggregateRepository