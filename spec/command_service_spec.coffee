describe 'CommandService', ->

  sinon    = require 'sinon'
  expect   = require 'expect'
  eventric = require 'eventric'

  AggregateRoot      = eventric 'AggregateRoot'
  ReadAggregateRoot  = eventric 'ReadAggregateRoot'
  DomainEventService = eventric 'DomainEventService'
  CommandService     = eventric 'CommandService'

  Repository         = require('sixsteps-client')('Repository')

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

    it.only 'should return the corresponding ReadAggregate', ->
      expect(readAggregate).to.be.a ReadAggregateRoot

    it 'should store the aggregate into a local cache using its ID', ->
      expect(CommandService.aggregateCache[42]).to.be.a AggregateRoot

    it 'should call the create method of the given aggregate', ->
      expect(myAggregateStub.create.calledOnce).to.be.ok()

    it 'should call the _domainEvent method of the given aggregate', ->
      expect(myAggregateStub._domainEvent.calledWith 'create').to.be.ok()

    it 'should call the getDomainEvents method of the given aggregate', ->
      expect(myAggregateStub.getDomainEvents.calledOnce).to.be.ok()

    it 'should call the handle function of the DomainEventService', ->
      expect(DomainEventService.handle.calledOnce).to.be.ok()

  describe '#handle', ->

    aggregateId = 1
    MyAggregate = null
    beforeEach ->
      class MyAggregate extends AggregateRoot
        _aggregateId: aggregateId
        myAggregateFunction: sandbox.spy()

    it 'should call the command on the aggregate', ->
      myAggregate = new MyAggregate
      sandbox.stub DomainEventService, 'handle'
      stub = sandbox.stub(Repository, 'fetchById')
        .withArgs(aggregateId)
        .returns(myAggregate)
      CommandService.handle 1, 'myAggregateFunction'
      expect(myAggregate.myAggregateFunction.calledOnce).to.be.ok()

    it 'should pass the accumulated domainEvents from the Aggregate to the DomainEventService', ->
      myAggregate = new MyAggregate
      events = {}
      stub = sandbox.stub DomainEventService, 'handle'
      sandbox.stub(Repository, 'fetchById')
        .withArgs(aggregateId)
        .returns(myAggregate)
      sandbox.stub(MyAggregate::, 'getDomainEvents')
        .returns(events)
      CommandService.handle 1, 'myAggregateFunction'
      expect(stub.withArgs(events).calledOnce).to.be.ok()

  xit 'should have a fetch function'

  xit 'should have a remove function'

  xit 'should have a destroy function'
