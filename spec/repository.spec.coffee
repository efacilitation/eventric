describe  'Repository', ->
  DomainEvent = eventric.require 'DomainEvent'
  repository = null
  domainEvent = null
  EventStoreStub = null
  AggregateStub = null
  aggregateDefinition = null

  beforeEach ->
    class EventStore
      find: ->
      save: ->
    EventStoreStub = sinon.createStubInstance EventStore
    domainEvent = new DomainEvent
      name: 'create'
      aggregate:
        id: 23
        name: 'Foo'
        changed:
          name: 'John'
    EventStoreStub.find.yields null, [
      domainEvent
    ]

    class AggregateStub
      applyDomainEvents: sandbox.stub()

    eventricMock =
      require: sandbox.stub()
    eventricMock.require.withArgs('HelperAsync').returns eventric.require 'HelperAsync'
    eventricMock.require.withArgs('HelperUnderscore').returns eventric.require 'HelperUnderscore'
    eventricMock.require.withArgs('Aggregate').returns AggregateStub

    mockery.registerMock 'eventric', eventricMock

    Repository = eventric.require 'Repository'
    repository = new Repository
      aggregateName: 'Foo'
      eventStore: EventStoreStub


  describe '#findById', ->

    it 'should return an aggregate', (done) ->
      repository.findById 23, (err, aggregate) ->
        expect(aggregate).to.be.an.instanceof AggregateStub
        done()


    it 'should ask the adapter for the DomainEvents matching the AggregateId', (done) ->
      repository.findById 23, ->
        expect(EventStoreStub.find.calledWith('Foo', {'aggregate.id': 23})).to.be.true
        done()


    it 'should call applyDomainEvents on the instantiated ReadAggregate', (done) ->
      repository.findById 23, (err, aggregate) ->
        expect(AggregateStub::applyDomainEvents).to.have.been.calledWith [domainEvent]
        done()


  describe '#find', ->

    query        = null
    findIdsStub  = null
    findByIdStub = null
    adapterStub  = null
    beforeEach ->
      query = {}
      findIdsStub  = sandbox.stub repository, 'findIds'
      findIdsStub.yields null, [42, 23]
      findByIdStub = sandbox.stub repository, 'findById'
      findByIdStub.yields null, new AggregateStub


    it 'should call findIds to get all aggregateIds matching the query', (done) ->
      repository.find query, ->
        expect(findIdsStub.calledWith query).to.be.true
        done()

    it 'should call findById for every aggregateId found', (done) ->
      repository.find query, ->
        expect(findByIdStub.calledWith 42).to.be.true
        expect(findByIdStub.calledWith 23).to.be.true
        done()

    it 'should return aggregate instances matching the given query', (done) ->
      repository.find query, (err, aggregate) ->
        expect(aggregate.length).to.equal 2
        expect(aggregate[0]).to.be.an.instanceof AggregateStub
        expect(aggregate[1]).to.be.an.instanceof AggregateStub
        done()

  describe '#findOne', ->

    it 'should call find and return only one result', (done) ->
      findStub = sandbox.stub repository, 'find'
      findStub.yields null, [1, 2]
      repository.findOne {}, (err, result) ->
        expect(result).to.equal 1
        done()


  describe '#findIds', ->

    it 'should return all AggregateIds matching the given query', (done) ->
      repository.findIds {}, (err, aggregateIds) ->
        expect(aggregateIds.length).to.equal 1
        expect(aggregateIds[0]).to.equal 23
        done()
