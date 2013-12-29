describe 'Aggregate Scenario', ->

  sinon    = require 'sinon'
  expect   = require 'expect'
  eventric = require 'eventric'

  CommandService     = eventric 'CommandService'
  DomainEventService = eventric 'DomainEventService'
  AggregateRoot      = eventric 'AggregateRoot'

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
        # stub the domaineventservice
        DomainEventServiceTriggerSpy = sandbox.spy DomainEventService, 'trigger'

        # create a stub for the CommandService callback
        createdCallback = sandbox.stub()

        # now we tell the commandservice to create the aggregate for us
        CommandService.create EnderAggregate, createdCallback

      it 'then the DomainEventService should haved triggered a "create" DomainEvent', ->
        expect(DomainEventServiceTriggerSpy.calledWith 'DomainEvent', sinon.match.has 'name', 'create').to.be.ok()