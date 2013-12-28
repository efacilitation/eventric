describe 'CommandService', ->

  sinon    = require 'sinon'
  expect   = require 'expect'
  eventric = require 'eventric'

  AggregateRoot      = eventric 'AggregateRoot'
  DomainEventService = eventric 'DomainEventService'
  CommandService     = eventric 'CommandService'

  Repository         = require('sixsteps-client')('SixStepsRepository')

  sandbox = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

  afterEach ->
    sandbox.restore()

  # TODO: test instead what the function does!
  it 'should have a create function', ->
    expect(CommandService.create).to.be.a Function

  # TODO: test instead what the function does!
  it 'should have a fetch function', ->
    expect(CommandService.fetch).to.be.a Function

  # TODO: test instead what the function does!
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
