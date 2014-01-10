describe 'CommandService', ->

  sinon    = require 'sinon'
  expect   = require 'expect'
  eventric = require 'eventric'

  AggregateRoot           = eventric 'AggregateRoot'
  AggregateRepository     = eventric 'AggregateRepository'
  ReadAggregateRoot       = eventric 'ReadAggregateRoot'
  DomainEventService      = eventric 'DomainEventService'
  CommandService          = eventric 'CommandService'

  sandbox = null
  aggregateStubId = 1
  myAggregateStub = null
  aggregateRepositoryStub = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

    # build Aggregate Stub
    myAggregateStub = sinon.createStubInstance AggregateRoot
    myAggregateStub.myAggregateFunction = sandbox.stub()
    myAggregateStub.id = aggregateStubId

    # stub the repository
    aggregateRepositoryStub = sinon.createStubInstance AggregateRepository
    aggregateRepositoryStub.findById.withArgs(aggregateStubId).returns(myAggregateStub)
    aggregateRepositoryStub._saveDomainEvents = sinon.stub()

    # stub the DomainEventService
    sandbox.stub DomainEventService

  afterEach ->
    sandbox.restore()

  describe '#createAggregate', ->

    aggregateId = null
    readAggregate = null
    commandService = null
    beforeEach ->
      # instantiate the CommandService with the ReadAggregateRepository stub
      commandService = new CommandService aggregateRepositoryStub

      # create an Aggregate Class stub which returns the myAggregateStub on instantiation
      AggregateStub = sandbox.stub().returns myAggregateStub

      # call the create method on the CommandService with the Aggregate Class stub
      aggregateId = commandService.createAggregate AggregateStub

    it 'should call the create method of the given aggregate', ->
      expect(myAggregateStub.create.calledOnce).to.be.ok()

    it 'should return the aggregateId', ->
      expect(aggregateId).to.be aggregateStubId

  describe '#commandAggregate', ->

    commandService = null
    beforeEach ->
      # instantiate the command service
      commandService = new CommandService aggregateRepositoryStub

    it 'should call the command on the aggregate', ->
      commandService.commandAggregate 1, 'myAggregateFunction'
      expect(myAggregateStub.myAggregateFunction.calledOnce).to.be.ok()

    it 'should store the aggregate into a local cache using its ID', ->
      commandService.commandAggregate 1, 'myAggregateFunction'
      expect(commandService.aggregateCache[1]).to.be.a AggregateRoot

    it 'should call the generateDomainEvent method of the given aggregate', ->
      commandService.commandAggregate 1, 'myAggregateFunction'
      expect(myAggregateStub.generateDomainEvent.calledWith 'myAggregateFunction').to.be.ok()

    it 'should pass the accumulated domainEvents from the Aggregate to the DomainEventService', ->
      events = {}
      myAggregateStub.getDomainEvents.returns events

      commandService.commandAggregate 1, 'myAggregateFunction'
      expect(DomainEventService.handle.withArgs(events).calledOnce).to.be.ok()

    it 'should return the aggregateId', ->
      aggregateId = commandService.commandAggregate 1, 'myAggregateFunction'
      expect(aggregateId).to.be 1