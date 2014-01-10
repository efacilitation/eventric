describe 'Create new Aggregate Scenario', ->

  sinon    = require 'sinon'
  expect   = require 'expect'
  eventric = require 'eventric'

  CommandService          = eventric 'CommandService'
  DomainEventService      = eventric 'DomainEventService'
  AggregateRoot           = eventric 'AggregateRoot'
  AggregateRepository     = eventric 'AggregateRepository'

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
      aggregateRepositoryStub      = null
      createdCallback              = null
      beforeEach ->
        # stub the DomainEventService.trigger
        DomainEventServiceTriggerSpy = sandbox.stub DomainEventService, 'trigger'

        # now we tell the commandservice to create the aggregate for us
        aggregateRepositoryStub = sinon.createStubInstance AggregateRepository
        aggregateRepositoryStub._saveDomainEvents = sinon.stub()
        commandService = new CommandService aggregateRepositoryStub
        commandService.createAggregate EnderAggregate

      it 'then the DomainEventService should have triggered a "create" DomainEvent', ->
        expect(DomainEventServiceTriggerSpy.calledWith 'DomainEvent', sinon.match.has 'name', 'create').to.be.ok()