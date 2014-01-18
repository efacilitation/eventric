describe 'ReadAggregateRepositorySpec', ->

  sinon    = require 'sinon'
  expect   = require 'expect.js'
  eventric = require 'eventric'

  ReadAggregateRepository = eventric 'ReadAggregateRepository'
  ReadAggregateRoot       = eventric 'ReadAggregateRoot'
  EventStore              = eventric 'MongoDBEventStore'

  class ReadFoo extends ReadAggregateRoot
    @prop 'name'


  sandbox = null
  readAggregateRepository = null
  EventStoreStub = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

    EventStoreStub = sinon.createStubInstance EventStore

    readAggregateRepository = new ReadAggregateRepository 'Foo', EventStoreStub
    readAggregateRepository.registerClass 'ReadFoo', ReadFoo

  afterEach ->
    sandbox.restore()

  describe '#findById', ->

    it 'should return a instantiated ReadAggregate', ->
      readAggregateRepository.findById 'ReadFoo', 23, (err, readAggregate) ->
        expect(readAggregate).to.be.a ReadFoo

    it 'should ask the adapter for the DomainEvents matching the AggregateId', ->
      readAggregateRepository.findById 'ReadFoo', 23, ->
      expect(EventStoreStub.findByAggregateId.calledWith('Foo', 23)).to.be.ok()

    it 'should return a instantiated ReadAggregate containing the applied DomainEvents', ->
      readAggregate = readAggregateRepository.findById 'ReadFoo', 23, (err, readAggregate) ->
        expect(readAggregate.name).to.be 'John'


  describe.skip '#find', ->

    criteria = null
    findByIdStub = null
    adapterStub = null
    beforeEach ->
      criteria = {}
      findByIdStub = sandbox.stub readAggregateRepository, 'findById', -> new ReadFoo
      EventStoreStub.findIds.retuns -> [42]

    it 'should ask the EventStore for the AggregateIds matching the DomainEvent-Criteria', ->
      # stub _findAggregateIdsByDomainEventCriteria to return an example AggregateId
      readAggregateRepository.find criteria
      expect(EventStoreStub.calledWith criteria).to.be.ok()

    it 'should call findById for every aggregateId found', ->
      readAggregateRepository.find criteria
      expect(findByIdStub.calledWith 42).to.be.ok()

    it 'should return ReadAggregate instances matching the given query-criteria', ->
      readAggregates = readAggregateRepository.find criteria
      expect(readAggregates.length).to.be 1
      expect(readAggregates[0]).to.be.a ReadFoo

  describe.skip '#findOne', ->

    it 'should call find and return only one result'


  describe.skip '#findIds', ->

    it 'should return all AggregateIds matching the given query-criteria', ->
      criteria = {}
      sandbox.stub readAggregateRepository._adapter, '_findAggregateIdsByDomainEventCriteria', -> [42]
      aggregateIds = readAggregateRepository.findIds criteria
      expect(aggregateIds.length).to.be 1
      expect(aggregateIds[0]).to.be 42
