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

    # now fetch all ReadAggregates matching the AggregateIds and return as array
    @findById aggregateId for aggregateId in aggregateIds


  findIds: (query) ->
    # only return aggregateIds
    projection =
      _id: 0
      aggregateId: 1

    # ask the adapter to find the ids and return them
    aggregateIds = @_findAggregateIdsByDomainEventCriteria query, projection


module.exports = ReadAggregateRepository