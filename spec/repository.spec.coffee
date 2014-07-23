describe  'Repository', ->
  DomainEvent = require 'eventric/domain_event'
  repository = null
  domainEvent = null
  EventStoreStub = null
  AggregateStub = null
  AggregateRootStub = null

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

    class AggregateRootStub
    aggregateRootStub = new AggregateRootStub

    class AggregateStub
      applyDomainEvents: sandbox.stub()
      root: aggregateRootStub
    mockery.registerMock './aggregate', AggregateStub
    mockery.registerMock 'eventric/aggregate', AggregateStub

    contextStub =
      name: 'someContext'
      getStore: sandbox.stub().returns EventStoreStub

    Repository = require 'eventric/repository'
    repository = new Repository
      aggregateName: 'Foo'
      context: contextStub


  describe '#findById', ->

    it 'should return an aggregate', (done) ->
      repository.findById 23, (err, aggregate) ->
        expect(aggregate).to.be.an.instanceof AggregateRootStub
        done()


    it 'should ask the adapter for the DomainEvents matching the AggregateId', (done) ->
      repository.findById 23, ->
        expect(EventStoreStub.find.calledWith('someContext.events', {'aggregate.name': 'Foo', 'aggregate.id': 23})).to.be.true
        done()


    it 'should call applyDomainEvents on the instantiated Aggregate', (done) ->
      repository.findById 23, (err, aggregate) ->
        expect(AggregateStub::applyDomainEvents).to.have.been.calledWith [domainEvent]
        done()

