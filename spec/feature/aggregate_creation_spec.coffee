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
      createdCallback              = null
      beforeEach ->
        # stub the DomainEventService.trigger
        DomainEventServiceTriggerSpy = sandbox.stub DomainEventService, 'trigger'

        # now we tell the commandservice to create the aggregate for us
        commandService = new CommandService null, sinon.createStubInstance ReadAggregateRepository
        commandService.create EnderAggregate

      it 'then the DomainEventService should haved triggered a "create" DomainEvent', ->
        expect(DomainEventServiceTriggerSpy.calledWith 'DomainEvent', sinon.match.has 'name', 'create').to.be.ok()