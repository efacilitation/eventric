describe 'CommandService', ->

  sinon    = require 'sinon'
  expect   = require 'expect.js'
  eventric = require 'eventric'

  AggregateRoot           = eventric 'AggregateRoot'
  AggregateRepository     = eventric 'AggregateRepository'
  ReadAggregateRoot       = eventric 'ReadAggregateRoot'
  DomainEventService      = eventric 'DomainEventService'
  CommandService          = eventric 'CommandService'

  sandbox = null
  aggregateStubId = 1
  exampleAggregateStub = null
  aggregateRepositoryStub = null
  domainEventService = null
  beforeEach ->
    sandbox = sinon.sandbox.create()

    # example aggregate
    class ExampleAggregate extends AggregateRoot

    # build ExampleAggregateStub
    exampleAggregateStub = sinon.createStubInstance ExampleAggregate
    exampleAggregateStub.doSomething = sandbox.stub()
    exampleAggregateStub.id = aggregateStubId

    # stub the repository
    aggregateRepositoryStub = sinon.createStubInstance AggregateRepository

    # getClass returns a Stub which returns the ExampleAggregateStub on instantiation
    aggregateRepositoryStub.getClass.returns sandbox.stub().returns exampleAggregateStub

    # stub the DomainEventService
    domainEventService = sinon.createStubInstance DomainEventService
    domainEventService.saveAndTrigger.yields null

  afterEach ->
    sandbox.restore()

  describe '#createAggregate', ->

    commandService = null
    beforeEach ->
      # findById should find nothing
      aggregateRepositoryStub.findById.yields null, null

      # instantiate the CommandService with the ReadAggregateRepository stub
      commandService = new CommandService domainEventService, aggregateRepositoryStub

    it 'should call the create method of the given aggregate', (done) ->
      commandService.createAggregate 'ExampleAggregate', ->
        expect(exampleAggregateStub.create.calledOnce).to.be.ok()
        done()

    it 'should return the aggregateId', (done) ->
      commandService.createAggregate 'ExampleAggregate', (err, aggregateId) ->
        expect(aggregateId).to.be aggregateStubId
        done()

  describe '#commandAggregate', ->

    commandService = null
    beforeEach ->
      # findById should find something
      aggregateRepositoryStub.findById.yields null, exampleAggregateStub

      # instantiate the command service
      commandService = new CommandService domainEventService, aggregateRepositoryStub

    it 'should call the command on the aggregate', (done) ->
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', (err, aggregateId) ->
        expect(exampleAggregateStub.doSomething.calledOnce).to.be.ok()
        done()

    it 'should call the command on the aggregate with the given argument and an error callback', (done) ->
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', 'foo',  (err, aggregateId) ->
        expect(exampleAggregateStub.doSomething.calledWith 'foo', sinon.match.func).to.be.ok()
        done()

    it 'should call the command on the aggregate with the given arguments and an error callback', (done) ->
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', ['foo', 'bar'],  (err, aggregateId) ->
        expect(exampleAggregateStub.doSomething.calledWith 'foo', 'bar', sinon.match.func).to.be.ok()
        done()

    it 'should call the callback with an error if there was an error at the aggregate', (done) ->
      exampleAggregateStub.doSomething.yields 'AGGREGATE_ERROR'
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', ['foo', 'bar'], (err, aggregateId) ->
        expect(err).to.equal 'AGGREGATE_ERROR'
        done()

    it 'should not call the generateDomainEvent method of the given aggregate if there was an error at the aggregate', (done) ->
      exampleAggregateStub.doSomething.yields 'AGGREGATE_ERROR'
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', ['foo', 'bar'], (err, aggregateId) ->
        expect(exampleAggregateStub.generateDomainEvent.notCalled).to.be.ok()
        done()

    it 'should call the generateDomainEvent method of the given aggregate', (done) ->
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', (err, aggregateId) ->
        expect(exampleAggregateStub.generateDomainEvent.calledWith 'doSomething').to.be.ok()
        done()

    it 'should call saveAndTrigger on DomainEventService with the generated DomainEvents', (done) ->
      events = {}
      exampleAggregateStub.getDomainEvents.returns events

      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', (err, aggregateId) ->
        expect(domainEventService.saveAndTrigger.withArgs(events).calledOnce).to.be.ok()
        done()

    it 'should call the clearChanges method of the given aggregate', (done) ->
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', (err, aggregateId) ->
        expect(exampleAggregateStub.clearChanges.calledOnce).to.be.ok()
        done()

    it 'should return the aggregateId', (done) ->
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', (err, aggregateId) ->
        expect(aggregateId).to.be 1
        done()
