Repository = require('eventric')('Repository')

class ReadAggregateRepository extends Repository

  constructor: (_adapter, @_ReadAggregateClass) ->
    super _adapter


  findById: (id) ->
    # find domain events matching the aggregate id
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


  find: (query) ->
    # get AggregateIds matching the query
    aggregateIds = @findIds query

    # now find ReadAggregates matching the AggregateIds and return as array
    @findById aggregateId for aggregateId in aggregateIds


  findIds: (query) ->
    # ask the adapter to find the ids and return them
    aggregateIds = @_findAggregateIdsByDomainEventCriteria query

  findOne: (query) ->


module.exports = ReadAggregateRepository