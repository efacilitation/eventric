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
  readAggregateRepositoryStub = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

    # create ReadAggregateRepository.findById stub which returns an ReadAggregateRoot
    readAggregateRepositoryStub = sinon.createStubInstance ReadAggregateRepository
    readAggregateRepositoryStub.findById.returns new ReadAggregateRoot

  afterEach ->
    sandbox.restore()

  describe '#create', ->

    readAggregate = null
    myAggregateStub = null
    commandService = null
    beforeEach ->

      # instantiate the CommandService with the ReadAggregateRepository stub
      commandService = new CommandService null, readAggregateRepositoryStub

      # stub the DomainEventService
      sandbox.stub DomainEventService, 'handle'

      # create an Aggregate Class stub which returns the myAggregateStub on instantiation
      myAggregateStub = sinon.createStubInstance AggregateRoot
      myAggregateStub._id = 42
      AggregateStub = sandbox.stub().returns myAggregateStub

      # call the create method on the CommandService with the Aggregate Class stub
      readAggregate = commandService.create AggregateStub

    it 'should call the create method of the given aggregate', ->
      expect(myAggregateStub.create.calledOnce).to.be.ok()

    it 'should store the aggregate into a local cache using its ID', ->
      expect(commandService.aggregateCache[42]).to.be.a AggregateRoot

    it 'should call the _domainEvent method of the given aggregate', ->
      expect(myAggregateStub._domainEvent.calledWith 'create').to.be.ok()

    it 'should call the getDomainEvents method of the given aggregate', ->
      expect(myAggregateStub.getDomainEvents.calledOnce).to.be.ok()

    it 'should call the handle function of the DomainEventService', ->
      expect(DomainEventService.handle.calledOnce).to.be.ok()

    it 'should call the findById function of the ReadAggregateRepository', ->
      expect(readAggregateRepositoryStub.findById.calledOnce).to.be.ok()

    it 'should return the corresponding ReadAggregate', ->
      expect(readAggregate).to.be.a ReadAggregateRoot

  describe '#handle', ->

    aggregateId = 1
    MyAggregate = null
    myAggregate = null
    commandService = null
    DomainEventServiceStub = null
    beforeEach ->
      # build some Aggregate
      class MyAggregate extends AggregateRoot
        _aggregateId: aggregateId
        myAggregateFunction: sandbox.spy()

      myAggregate = new MyAggregate

      # stub the repository
      repository = sinon.createStubInstance Repository
      repository.fetchById.withArgs(aggregateId).returns(myAggregate)

      # stub the DomainEventService
      DomainEventServiceStub = sandbox.stub DomainEventService

      # instantiate the command service
      commandService = new CommandService repository, readAggregateRepositoryStub


    it 'should call the command on the aggregate', ->
      commandService.handle 1, 'myAggregateFunction'
      expect(myAggregate.myAggregateFunction.calledOnce).to.be.ok()

    it 'should pass the accumulated domainEvents from the Aggregate to the DomainEventService', ->
      # stub the getDomainEvents function on MyAggregate
      events = {}
      sandbox.stub(MyAggregate::, 'getDomainEvents').returns events

      # call the CommandService with the aggregateId and the function to handle
      commandService.handle 1, 'myAggregateFunction'
      expect(DomainEventService.handle.withArgs(events).calledOnce).to.be.ok()

    it 'should return the corresponding ReadAggregate', ->
      myAggregate = new MyAggregate
      readAggregate = commandService.handle 1, 'myAggregateFunction'
      expect(readAggregate).to.be.a ReadAggregateRoot




  xit 'should have a fetch function'

  xit 'should have a remove function'

  xit 'should have a destroy function'
