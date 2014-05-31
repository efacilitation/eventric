describe 'ReadAggregateRepositorySpec', ->
  ReadAggregateRepository = eventric.require 'ReadAggregateRepository'
  ReadAggregateRoot       = eventric.require 'ReadAggregateRoot'

  class ReadFoo extends ReadAggregateRoot

  readAggregateRepository = null
  EventStoreStub = null
  beforeEach ->
    class EventStore
      find: ->
      save: ->
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


  describe '#findById', ->

    it 'should return an instantiated ReadAggregate', (done) ->
      readAggregateRepository.findById 'ReadFoo', 23, (err, readAggregate) ->
        expect(readAggregate).to.be.an.instanceof ReadFoo
        done()

    it 'should ask the adapter for the DomainEvents matching the AggregateId', (done) ->
      readAggregateRepository.findById 'ReadFoo', 23, ->
        expect(EventStoreStub.find.calledWith('Foo', {'aggregate.id': 23})).to.be.true
        done()

    it 'should return an instantiated ReadAggregate containing the applied DomainEvents', (done) ->
      readAggregateRepository.findById 'ReadFoo', 23, (err, readAggregate) ->
        expect(readAggregate.name).to.equal 'John'
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
        expect(findIdsStub.calledWith 'ReadFoo', query).to.be.true
        done()

    it 'should call findById for every aggregateId found', (done) ->
      readAggregateRepository.find 'ReadFoo', query, ->
        expect(findByIdStub.calledWith 'ReadFoo', 42).to.be.true
        expect(findByIdStub.calledWith 'ReadFoo', 23).to.be.true
        done()

    it 'should return ReadAggregate instances matching the given query', (done) ->
      readAggregateRepository.find 'ReadFoo', query, (err, readAggregates) ->
        expect(readAggregates.length).to.equal 2
        expect(readAggregates[0]).to.be.an.instanceof ReadFoo
        expect(readAggregates[1]).to.be.an.instanceof ReadFoo
        done()

  describe '#findOne', ->

    it 'should call find and return only one result', (done) ->
      findStub = sandbox.stub readAggregateRepository, 'find'
      findStub.yields null, [1, 2]
      readAggregateRepository.findOne 'ReadFoo', {}, (err, result) ->
        expect(result).to.equal 1
        done()


  describe '#findIds', ->

    it 'should return all AggregateIds matching the given query', (done) ->
      readAggregateRepository.findIds 'ReadFoo', {}, (err, aggregateIds) ->
        expect(aggregateIds.length).to.equal 1
        expect(aggregateIds[0]).to.equal 23
        done()
