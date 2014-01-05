Repository = require('eventric')('Repository')

class ReadAggregateRepository extends Repository

  constructor: (_adapter, @_ReadAggregateClass) ->
    super _adapter

  findById: (id) ->
    # find domain events matching the aggregate id first
    domainEvents = @_findDomainEventsByAggregateId id

    # create the ReadAggregate instance
    readAggregate = new @_ReadAggregateClass

    # apply the domainevents on the ReadAggregate
    readAggregate._applyChanges domainEvent._changed for domainEvent in domainEvents

    # return the readAggregate
    readAggregate


  findByIds: (ids) ->
    # call finyById for every given Id
    @findById id for id in ids


  find: (query, projection) ->
    # find ReadAggregates based on query and projection

    # get AggregateIds first
    aggregateIds = @_findAggregateIdsByDomainEventCriteria query, projection

    # now fetch all ReadAggregates matching the AggregateIds
    readAggregates = []
    readAggregates.push @findById aggregateId for aggregateId in aggregateIds

    # return the readAggregates found
    readAggregates


  findIds: (query) ->
    # only return aggregateIds
    projection =
      _id: 0
      aggregateId: 1

    # ask the adapter to find the ids
    results = @_findDomainEventsByAggregateId query, projection

    # convert to array of ids and return
    object.id for object in results


  _findAggregateDataById: (id) ->
    # ask the adapter to findById
    @_adapter.findById id

  _findAggregateData: (query, projection) ->
    # ask the adapter to find based on query and projection
    @_adapter.find query, projection


  _createReadAggregateInstance: ->
    # create and return a ReadAggregate instance with the given data
    new @_ReadAggregateClass

module.exports = ReadAggregateRepository