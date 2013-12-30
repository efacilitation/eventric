describe 'Aggregate Scenario', ->

  sinon    = require 'sinon'
  expect   = require 'expect'
  eventric = require 'eventric'

  CommandService          = eventric 'CommandService'
  DomainEventService      = eventric 'DomainEventService'
  AggregateRoot           = eventric 'AggregateRoot'
  ReadAggregateRepository = eventric 'ReadAggregateRepository'

  sandbox = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

  afterEach ->
    sandbox.restore()

  describe 'given we want to instantiate a new Aggregate', ->

    EnderAggregate = null
    beforeEach ->
      # so we have an aggregate defined
      class EnderAggregate extends AggregateRoot

    describe 'when we tell the CommandService to create an Aggregate', ->

      DomainEventServiceTriggerSpy = null
      readAggregateRepositoryStub  = null
      createdCallback              = null
      beforeEach ->
        # stub the DomainEventService.trigger
        DomainEventServiceTriggerSpy = sandbox.stub DomainEventService, 'trigger'

        # now we tell the commandservice to create the aggregate for us
        readAggregateRepositoryStub = sinon.createStubInstance ReadAggregateRepository
        commandService = new CommandService null, readAggregateRepositoryStub
        commandService.create EnderAggregate

      it 'then the DomainEventService should have triggered a "create" DomainEvent', ->
        expect(DomainEventServiceTriggerSpy.calledWith 'DomainEvent', sinon.match.has 'name', 'create').to.be.ok()

      it 'and the ReadAggregateRepository should have been asked to find a ReadAggregate by its ID', ->
        # TODO this should actually check if the adapter inside of the repository got called
        expect(readAggregateRepositoryStub.findById.calledOnce).to.be.ok()