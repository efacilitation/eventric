describe 'CommandService', ->
  AggregateRepository     = eventric.require 'AggregateRepository'
  DomainEventService      = eventric.require 'DomainEventService'
  AggregateRoot           = eventric.require 'AggregateRoot'
  CommandService           = eventric.require 'CommandService'

  aggregateStubId = 1
  class ExampleAggregate
    doSomething: sandbox.stub()
    id: aggregateStubId
  aggregateRepositoryStub = null
  domainEventService = null
  CommandService = null
  beforeEach ->


    # stub the repository
    aggregateRepositoryStub = sinon.createStubInstance AggregateRepository

    # getAggregateObj returns a Stub which returns the ExampleAggregateStub on instantiation
    aggregateRepositoryStub.getAggregateClass.returns ExampleAggregate

    # stub the DomainEventService
    domainEventService = sinon.createStubInstance DomainEventService
    domainEventService.saveAndTrigger.yields null



  describe '#createAggregate', ->

    commandService = null
    beforeEach ->
      # findById should find nothing
      aggregateRepositoryStub.findById.yields null, null

      AggregateRoot = eventric.require 'AggregateRoot'
      sandbox.stub AggregateRoot::

      # instantiate the CommandService with the ReadAggregateRepository stub
      CommandService = eventric.require 'CommandService'
      commandService = new CommandService domainEventService, aggregateRepositoryStub


    it 'should return the aggregateId', (done) ->
      commandService.createAggregate 'ExampleAggregate', (err, aggregateId) ->
        expect(aggregateId).to.equal aggregateStubId
        done()


  describe '#commandAggregate', ->
    exampleAggregateStub = null
    commandService = null

    beforeEach ->
      # build ExampleAggregateStub
      exampleAggregateStub = sinon.createStubInstance AggregateRoot
      exampleAggregateStub.doSomething = sandbox.stub()
      exampleAggregateStub.id = aggregateStubId


      # findById should find something
      aggregateRepositoryStub.findById.yields null, exampleAggregateStub

      # instantiate the command service
      commandService = new CommandService domainEventService, aggregateRepositoryStub


    it 'should call the command on the aggregate', (done) ->
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', (err, aggregateId) ->
        expect(exampleAggregateStub.doSomething.calledOnce).to.be.true
        done()


    it 'should call the command on the aggregate with the given argument and an error callback', (done) ->
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', 'foo',  (err, aggregateId) ->
        expect(exampleAggregateStub.doSomething.calledWith 'foo', sinon.match.func).to.be.true
        done()


    it 'should call the command on the aggregate with the given arguments and an error callback', (done) ->
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', ['foo', 'bar'],  (err, aggregateId) ->
        expect(exampleAggregateStub.doSomething.calledWith 'foo', 'bar', sinon.match.func).to.be.true
        done()


    it 'should call the callback with an error if there was an error at the aggregate', (done) ->
      exampleAggregateStub.doSomething.yields 'AGGREGATE_ERROR'
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', ['foo', 'bar'], (err, aggregateId) ->
        expect(err).to.equal 'AGGREGATE_ERROR'
        done()


    it 'should not call the generateDomainEvent method of the given aggregate if there was an error at the aggregate', (done) ->
      exampleAggregateStub.doSomething.yields 'AGGREGATE_ERROR'
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', ['foo', 'bar'], (err, aggregateId) ->
        expect(exampleAggregateStub.generateDomainEvent.notCalled).to.be.true
        done()


    it 'should call the generateDomainEvent method of the given aggregate', (done) ->
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', (err, aggregateId) ->
        expect(exampleAggregateStub.generateDomainEvent.calledWith 'doSomething').to.be.true
        done()


    it 'should call saveAndTrigger on DomainEventService with the generated DomainEvents', (done) ->
      events = {}
      exampleAggregateStub.getDomainEvents.returns events

      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', (err, aggregateId) ->
        expect(domainEventService.saveAndTrigger.withArgs(events).calledOnce).to.be.true
        done()


    it 'should call the clearChanges method of the given aggregate', (done) ->
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', (err, aggregateId) ->
        expect(exampleAggregateStub.clearChanges.calledOnce).to.be.true
        done()


    it 'should return the aggregateId', (done) ->
      commandService.commandAggregate 'ExampleAggregate', 1, 'doSomething', (err, aggregateId) ->
        expect(aggregateId).to.equal 1
        done()
