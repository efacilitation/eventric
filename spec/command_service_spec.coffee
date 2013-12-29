describe 'CommandService', ->

  sinon    = require 'sinon'
  expect   = require 'expect'
  eventric = require 'eventric'

  AggregateRoot      = eventric 'AggregateRoot'
  DomainEventService = eventric 'DomainEventService'
  CommandService     = eventric 'CommandService'

  Repository         = require('sixsteps-client')('Repository')

  sandbox = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

  afterEach ->
    sandbox.restore()

  describe '#create', ->

    aggregateId = null
    myAggregateStub = null
    beforeEach ->
      sandbox.stub DomainEventService, 'handle'

      myAggregateStub = sinon.createStubInstance AggregateRoot
      myAggregateStub._id = 42

      AggregateStub = sandbox.stub().returns myAggregateStub
      aggregateId = CommandService.create AggregateStub

    it 'should return the ID of the instantiated Aggregate', ->
      expect(aggregateId).to.be 42

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


  # TODO: test instead what the function does!
  it 'should have a create function', ->
    expect(CommandService.create).to.be.a Function

  # TODO: test instead what the function does!
  it 'should have a fetch function', ->
    expect(CommandService.fetch).to.be.a Function

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

  # TODO: test instead what the function does!
  it 'should have a remove function', ->
    expect(CommandService.remove).to.be.a Function

  # TODO: test instead what the function does!
  it 'should have a destroy function', ->
    expect(CommandService.destroy).to.be.a Function
