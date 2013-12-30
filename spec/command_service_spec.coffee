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
  aggregateId = 1
  myAggregateStub = null
  readAggregateRepositoryStub = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

    # create ReadAggregateRepository.findById stub which returns an ReadAggregateRoot
    readAggregateRepositoryStub = sinon.createStubInstance ReadAggregateRepository
    readAggregateRepositoryStub.findById.returns new ReadAggregateRoot

    # build Aggregate Stub
    myAggregateStub = sinon.createStubInstance AggregateRoot
    myAggregateStub.myAggregateFunction = sandbox.stub()
    myAggregateStub._id = aggregateId

    # stub the DomainEventService
    sandbox.stub DomainEventService

  afterEach ->
    sandbox.restore()

  describe '#create', ->

    readAggregate = null
    commandService = null
    beforeEach ->
      # instantiate the CommandService with the ReadAggregateRepository stub
      commandService = new CommandService null, readAggregateRepositoryStub

      # create an Aggregate Class stub which returns the myAggregateStub on instantiation
      AggregateStub = sandbox.stub().returns myAggregateStub

      # call the create method on the CommandService with the Aggregate Class stub
      readAggregate = commandService.create AggregateStub

    it 'should call the create method of the given aggregate', ->
      expect(myAggregateStub.create.calledOnce).to.be.ok()

    it 'should return the corresponding ReadAggregate', ->
      expect(readAggregate).to.be.a ReadAggregateRoot

  describe '#handle', ->

    commandService = null
    beforeEach ->
      # stub the repository
      repository = sinon.createStubInstance Repository
      repository.fetchById.withArgs(aggregateId).returns(myAggregateStub)

      # instantiate the command service
      commandService = new CommandService repository, readAggregateRepositoryStub

    it 'should call the command on the aggregate', ->
      commandService.handle 1, 'myAggregateFunction'
      expect(myAggregateStub.myAggregateFunction.calledOnce).to.be.ok()

    it 'should store the aggregate into a local cache using its ID', ->
      commandService.handle 1, 'myAggregateFunction'
      expect(commandService.aggregateCache[1]).to.be.a AggregateRoot

    it 'should call the _domainEvent method of the given aggregate', ->
      commandService.handle 1, 'myAggregateFunction'
      expect(myAggregateStub._domainEvent.calledWith 'myAggregateFunction').to.be.ok()

    it 'should pass the accumulated domainEvents from the Aggregate to the DomainEventService', ->
      events = {}
      myAggregateStub.getDomainEvents.returns events

      commandService.handle 1, 'myAggregateFunction'
      expect(DomainEventService.handle.withArgs(events).calledOnce).to.be.ok()

    it 'should call the findById function of the ReadAggregateRepository', ->
      commandService.handle 1, 'myAggregateFunction'
      expect(readAggregateRepositoryStub.findById.calledOnce).to.be.ok()

    it 'should return the corresponding ReadAggregate', ->
      readAggregate = commandService.handle 1, 'myAggregateFunction'
      expect(readAggregate).to.be.a ReadAggregateRoot




  xit 'should have a fetch function'

  xit 'should have a remove function'

  xit 'should have a destroy function'
