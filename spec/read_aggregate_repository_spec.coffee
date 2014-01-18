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
    EventStoreStub.find.yields null, [
      name: 'create'
      aggregate:
        id: 23
        name: 'Foo'
        changed:
          props:
            name: 'John'
    ]

    readAggregateRepository = new ReadAggregateRepository 'Foo', EventStoreStub
    readAggregateRepository.registerClass 'ReadFoo', ReadFoo

  afterEach ->
    sandbox.restore()

  describe '#findById', ->

    it 'should return an instantiated ReadAggregate', (done) ->
      readAggregateRepository.findById 'ReadFoo', 23, (err, readAggregate) ->
        expect(readAggregate).to.be.a ReadFoo
        done()

    it 'should ask the adapter for the DomainEvents matching the AggregateId', (done) ->
      readAggregateRepository.findById 'ReadFoo', 23, ->
        expect(EventStoreStub.find.calledWith('Foo', {'aggregate.id': 23})).to.be.ok()
        done()

    it 'should return an instantiated ReadAggregate containing the applied DomainEvents', (done) ->
      readAggregateRepository.findById 'ReadFoo', 23, (err, readAggregate) ->
        expect(readAggregate.name).to.be 'John'
        done()


  describe '#find', ->

    query        = null
    findIdsStub  = null
    findByIdStub = null
    adapterStub  = null
    beforeEach ->
      query = {}
      findIdsStub  = sandbox.stub readAggregateRepository, 'findIds'
      findIdsStub.yields null, [42, 23]
      findByIdStub = sandbox.stub readAggregateRepository, 'findById'
      findByIdStub.yields null, new ReadFoo


    it 'should call findIds to get all aggregateIds matching the query', (done) ->
      readAggregateRepository.find 'ReadFoo', query, ->
        expect(findIdsStub.calledWith 'ReadFoo', query).to.be.ok()
        done()

    it 'should call findById for every aggregateId found', (done) ->
      readAggregateRepository.find 'ReadFoo', query, ->
        expect(findByIdStub.calledWith 'ReadFoo', 42).to.be.ok()
        expect(findByIdStub.calledWith 'ReadFoo', 23).to.be.ok()
        done()

    it 'should return ReadAggregate instances matching the given query', (done) ->
      readAggregateRepository.find 'ReadFoo', query, (err, readAggregates) ->
        expect(readAggregates.length).to.be 2
        expect(readAggregates[0]).to.be.a ReadFoo
        expect(readAggregates[1]).to.be.a ReadFoo
        done()

  describe '#findOne', ->

    it 'should call find and return only one result', (done) ->
      findStub = sandbox.stub readAggregateRepository, 'find'
      findStub.yields null, [1, 2]
      readAggregateRepository.findOne 'ReadFoo', {}, (err, result) ->
        expect(result).to.be 1
        done()


  describe '#findIds', ->

    it 'should return all AggregateIds matching the given query', (done) ->
      readAggregateRepository.findIds 'ReadFoo', {}, (err, aggregateIds) ->
        expect(aggregateIds.length).to.be 1
        expect(aggregateIds[0]).to.be 23
        done()
