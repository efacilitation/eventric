describe.only 'InMemoryAdapter', ->

  expect   = require 'expect'
  eventric = require 'eventric'

  RepositoryInMemoryAdapter = eventric 'RepositoryInMemoryAdapter'

  domainEvents = null
  beforeEach ->
    domainEvents = [
      {name: 'event1', metaData: {id: 42}}
      {name: 'event2', metaData: {id: 23}}
    ]

  describe '#saveDomainEvents', ->

    it 'should save the given DomainEvents', ->
      RepositoryInMemoryAdapter.saveDomainEvents domainEvents
      expect(RepositoryInMemoryAdapter._domainEvents.length).to.be 2

  describe '#findDomainEventsByAggregateId', ->

    it 'should return DomainEvents by AggregateId', ->
      RepositoryInMemoryAdapter._domainEvents = domainEvents
      domainEventsFound = RepositoryInMemoryAdapter.findDomainEventsByAggregateId 42
      expect(domainEventsFound.length).to.be 1
      expect(domainEventsFound[0].name).to.be 'event1'


  describe '#findAggregateIdsByDomainEventCriteria', ->

    it 'should return AggregateIds by DomainEvent criteria', ->
      # this actually just returns all aggregateIds in the store for now
      RepositoryInMemoryAdapter._domainEvents = domainEvents
      criteria = {}
      aggregateIds = RepositoryInMemoryAdapter.findAggregateIdsByDomainEventCriteria criteria
      expect(aggregateIds.length).to.be 2
      expect(aggregateIds[0]).to.be 42