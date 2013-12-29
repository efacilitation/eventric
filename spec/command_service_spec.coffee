describe 'CommandService', ->

  sinon    = require 'sinon'
  expect   = require 'expect'
  eventric = require 'eventric'

  AggregateRoot           = eventric 'AggregateRoot'
  ReadAggregateRoot       = eventric 'ReadAggregateRoot'
  ReadAggregateRepository = eventric 'ReadAggregateRepository'
  DomainEventService      = eventric 'DomainEventService'
  CommandService          = eventric 'CommandService'
  Repository              = eventric 'Repository'

  sandbox = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

  afterEach ->
    sandbox.restore()

  describe '#create', ->

    readAggregate = null
    myAggregateStub = null
    beforeEach ->
      sandbox.stub DomainEventService, 'handle'

      myAggregateStub = sinon.createStubInstance AggregateRoot
      myAggregateStub._id = 42

      AggregateStub = sandbox.stub().returns myAggregateStub
      readAggregate = CommandService.create AggregateStub

    it 'should call the create method of the given aggregate', ->
      expect(myAggregateStub.create.calledOnce).to.be.ok()

    it 'should store the aggregate into a local cache using its ID', ->
      expect(CommandService.aggregateCache[42]).to.be.a AggregateRoot

    it 'should call the _domainEvent method of the given aggregate', ->
      expect(myAggregateStub._domainEvent.calledWith 'create').to.be.ok()

    it 'should call the getDomainEvents method of the given aggregate', ->
      expect(myAggregateStub.getDomainEvents.calledOnce).to.be.ok()

    it 'should call the handle function of the DomainEventService', ->
      expect(DomainEventService.handle.calledOnce).to.be.ok()

    xit 'should call the findById function of the ReadAggregateRepository', ->
      expect(ReadAggregateRepository.findById.calledOnce).to.be.ok()

    it 'should return the corresponding ReadAggregate', ->
      expect(readAggregate).to.be.a ReadAggregateRoot

  describe '#handle', ->

    aggregateId = 1
    MyAggregate = null
    myAggregate = null
    DomainEventServiceStub = null
    beforeEach ->
      # stub the DomainEventService
      DomainEventServiceStub = sandbox.stub DomainEventService

      # build some Aggregate
      class MyAggregate extends AggregateRoot
        _aggregateId: aggregateId
        myAggregateFunction: sandbox.spy()

      myAggregate = new MyAggregate

      # stub the repository
      sandbox.stub(Repository, 'fetchById')
        .withArgs(aggregateId)
        .returns(myAggregate)


    it 'should call the command on the aggregate', ->
      CommandService.handle 1, 'myAggregateFunction'
      expect(myAggregate.myAggregateFunction.calledOnce).to.be.ok()

    it 'should pass the accumulated domainEvents from the Aggregate to the DomainEventService', ->
      events = {}
      sandbox.stub(MyAggregate::, 'getDomainEvents')
        .returns(events)
      CommandService.handle 1, 'myAggregateFunction'
      expect(DomainEventService.handle.withArgs(events).calledOnce).to.be.ok()

    it 'should return the corresponding ReadAggregate', ->
      myAggregate = new MyAggregate
      readAggregate = CommandService.handle 1, 'myAggregateFunction'
      expect(readAggregate).to.be.a ReadAggregateRoot




  xit 'should have a fetch function'

  xit 'should have a remove function'

  xit 'should have a destroy function'
