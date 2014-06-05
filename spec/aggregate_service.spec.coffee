describe 'AggregateService', ->
  AggregateRepository     = eventric.require 'AggregateRepository'
  DomainEventService      = eventric.require 'DomainEventService'
  Aggregate               = eventric.require 'Aggregate'
  AggregateService        = eventric.require 'AggregateService'

  aggregateStubId = 1
  exampleAggregate = null
  aggregateRepositoryStub = null
  domainEventService = null
  AggregateService = null
  beforeEach ->
    exampleAggregate =
      doSomething: sandbox.stub()
      create: sandbox.stub()
      id: aggregateStubId

    # stub the repository
    aggregateRepositoryStub = sinon.createStubInstance AggregateRepository

    # getAggregateDefinition returns a Stub which returns the ExampleAggregateStub on instantiation
    aggregateRepositoryStub.getAggregateDefinition.returns root: sinon.stub().returns exampleAggregate

    # stub the DomainEventService
    domainEventService = sinon.createStubInstance DomainEventService
    domainEventService.saveAndTrigger.yields null



  describe '#create', ->
    initialProps =
      some: 'thing'

    aggregateService = null
    beforeEach ->
      # findById should find nothing
      aggregateRepositoryStub.findById.yields null, null

      Aggregate = eventric.require 'Aggregate'
      sandbox.stub Aggregate::

      # instantiate the AggregateService with the ReadAggregateRepository stub
      AggregateService = eventric.require 'AggregateService'
      aggregateService = new AggregateService domainEventService, aggregateRepositoryStub


    it 'should return the aggregateId', (done) ->
      aggregateService.create 'ExampleAggregate', (err, aggregateId) ->
        expect(aggregateId).to.equal aggregateStubId
        done()


    describe 'given a create method is present on the aggregate', ->
      it 'should call the create method on the aggregate with the initial parameters', (done) ->
        aggregateService.create 'ExampleAggregate', initialProps, ->
          expect(exampleAggregate.create).to.have.been.calledWith initialProps
          done()


    describe 'given no create method is present on the aggregate', ->
      it 'should apply the initial paramters directly on the aggregate', (done) ->
        delete exampleAggregate.create
        aggregateService.create 'ExampleAggregate', initialProps, (err) ->
          expect(Aggregate::applyProps).to.have.been.calledWith initialProps
          done()


  describe '#command', ->
    exampleAggregateStub = null
    aggregateService = null

    beforeEach ->
      # build ExampleAggregateStub
      exampleAggregateStub = sinon.createStubInstance Aggregate
      exampleAggregateStub.doSomething = sandbox.stub()
      exampleAggregateStub.id = aggregateStubId


      # findById should find something
      aggregateRepositoryStub.findById.yields null, exampleAggregateStub

      # instantiate the command service
      aggregateService = new AggregateService domainEventService, aggregateRepositoryStub


    it 'should call the command on the aggregate', (done) ->
      aggregateService.command 'ExampleAggregate', 1, 'doSomething', (err, aggregateId) ->
        expect(exampleAggregateStub.doSomething.calledOnce).to.be.true
        done()


    it 'should call the command on the aggregate with the given argument and an error callback', (done) ->
      aggregateService.command 'ExampleAggregate', 1, 'doSomething', 'foo',  (err, aggregateId) ->
        expect(exampleAggregateStub.doSomething.calledWith 'foo', sinon.match.func).to.be.true
        done()


    it 'should call the command on the aggregate with the given arguments and an error callback', (done) ->
      aggregateService.command 'ExampleAggregate', 1, 'doSomething', ['foo', 'bar'],  (err, aggregateId) ->
        expect(exampleAggregateStub.doSomething.calledWith 'foo', 'bar', sinon.match.func).to.be.true
        done()


    it 'should call the callback with an error if there was an error at the aggregate', (done) ->
      exampleAggregateStub.doSomething.yields 'AGGREGATE_ERROR'
      aggregateService.command 'ExampleAggregate', 1, 'doSomething', ['foo', 'bar'], (err, aggregateId) ->
        expect(err).to.equal 'AGGREGATE_ERROR'
        done()


    it 'should not call the generateDomainEvent method of the given aggregate if there was an error at the aggregate', (done) ->
      exampleAggregateStub.doSomething.yields 'AGGREGATE_ERROR'
      aggregateService.command 'ExampleAggregate', 1, 'doSomething', ['foo', 'bar'], (err, aggregateId) ->
        expect(exampleAggregateStub.generateDomainEvent.notCalled).to.be.true
        done()


    it 'should call the generateDomainEvent method of the given aggregate', (done) ->
      aggregateService.command 'ExampleAggregate', 1, 'doSomething', (err, aggregateId) ->
        expect(exampleAggregateStub.generateDomainEvent.calledWith 'doSomething').to.be.true
        done()


    it 'should call saveAndTrigger on DomainEventService with the generated DomainEvents', (done) ->
      events = {}
      exampleAggregateStub.getDomainEvents.returns events

      aggregateService.command 'ExampleAggregate', 1, 'doSomething', (err, aggregateId) ->
        expect(domainEventService.saveAndTrigger.withArgs(events).calledOnce).to.be.true
        done()


    it 'should call the clearChanges method of the given aggregate', (done) ->
      aggregateService.command 'ExampleAggregate', 1, 'doSomething', (err, aggregateId) ->
        expect(exampleAggregateStub.clearChanges.calledOnce).to.be.true
        done()


    it 'should return the aggregateId', (done) ->
      aggregateService.command 'ExampleAggregate', 1, 'doSomething', (err, aggregateId) ->
        expect(aggregateId).to.equal 1
        done()
