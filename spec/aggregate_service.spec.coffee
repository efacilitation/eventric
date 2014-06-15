describe 'AggregateService', ->
  DomainEventService = eventric.require 'DomainEventService'

  aggregateStubId = 1
  exampleAggregateRoot = null
  repositoryStub = null
  domainEventService = null
  exampleAggregateStub = null
  AggregateService = null
  eventStoreStub = null
  thenStub = null
  catchStub = null
  beforeEach ->
    eventStoreStub = {}
    # TODO: stub promises in a more sane fashion
    catchStub = sandbox.stub()
    thenStub = sandbox.stub()
    class ExampleAggregateStub
      id: aggregateStubId
      create: sandbox.stub().returns
        then: thenStub.returns
          catch: catchStub
        catch: catchStub.returns
          then: thenStub
      command: sandbox.stub().returns
        then: thenStub.returns
          catch: catchStub
        catch: catchStub.returns
          then: thenStub
      generateDomainEvent: sandbox.stub()
      getDomainEvents: sandbox.stub()
    exampleAggregateStub = new ExampleAggregateStub

    repositoryStub =
      findById: sandbox.stub()

    # stub the DomainEventService
    domainEventService = sinon.createStubInstance DomainEventService
    domainEventService.saveAndTrigger.yields null

    eventricMock =
      require: sandbox.stub()
    eventricMock.require.withArgs('Aggregate').returns ExampleAggregateStub
    eventricMock.require.withArgs('Repository').returns -> repositoryStub
    eventricMock.require.withArgs('HelperUnderscore').returns eventric.require 'HelperUnderscore'
    eventricMock.require.withArgs('HelperAsync').returns eventric.require 'HelperAsync'
    mockery.registerMock 'eventric', eventricMock

    AggregateService = eventric.require 'AggregateService'


  describe '#create', ->
    initialProps =
      some: 'thing'

    aggregateService = null
    beforeEach ->
      # findById should find nothing
      repositoryStub.findById.yields null, null

      # instantiate the AggregateService with the ReadAggregateRepository stub
      aggregateService = new AggregateService
      aggregateService.initialize eventStoreStub, domainEventService
      aggregateService.registerAggregateDefinition 'ExampleAggregate', {}


    it 'should return the aggregateId', (done) ->
      thenStub.yields null
      aggregateService.create
        name: 'ExampleAggregate'
      .then (aggregateId) ->
        expect(aggregateId).to.equal aggregateStubId
        done()


  describe '#command', ->
    aggregateService = null

    beforeEach ->
      # findById should find something
      repositoryStub.findById.yields null, exampleAggregateStub

      # instantiate the command service
      aggregateService = new AggregateService
      aggregateService.initialize eventStoreStub, domainEventService
      aggregateService.registerAggregateDefinition 'ExampleAggregate', {}


    it 'should call the command on the aggregate with empty array of params', (done) ->
      thenStub.yields null
      aggregateService.command
        id: 1
        name: 'ExampleAggregate'
        methodName: 'doSomething'
      .then ->
        expect(exampleAggregateStub.command).to.have.been.calledWith
          name: 'doSomething'
          params: []
        done()


    it 'should call the command on the aggregate with the given argument and an error callback', (done) ->
      thenStub.yields null
      aggregateService.command
        name: 'ExampleAggregate'
        id: 1
        methodName: 'doSomething'
        methodParams: ['foo']
      .then ->
        expect(exampleAggregateStub.command).to.have.been.calledWith
          name: 'doSomething'
          params: ['foo']
        done()


    it 'should call the command on the aggregate with the given arguments and an error callback', (done) ->
      thenStub.yields null
      aggregateService.command
        name: 'ExampleAggregate'
        id: 1
        methodName: 'doSomething'
        methodParams: ['foo', 'bar']
      .then ->
        expect(exampleAggregateStub.command).to.have.been.calledWith
          name: 'doSomething'
          params: ['foo', 'bar']
        done()


    it 'should reject with an error if there was an error at the aggregate', (done) ->
      catchStub.yields 'AGGREGATE_ERROR'
      aggregateService.command
        name: 'ExampleAggregate'
        id: 1
        methodName: 'doSomething'
        methodParams: ['foo', 'bar']
      .catch (err) ->
        expect(err).to.equal 'AGGREGATE_ERROR'
        done()


    it 'should not call the generateDomainEvent method of the given aggregate if there was an error at the aggregate', (done) ->
      catchStub.yields 'AGGREGATE_ERROR'
      aggregateService.command
        name: 'ExampleAggregate'
        id: 1
        methodName: 'doSomething'
        methodParams: ['foo', 'bar']
      .catch ->
        expect(exampleAggregateStub.generateDomainEvent.notCalled).to.be.true
        done()


    it 'should call the generateDomainEvent method of the given aggregate', (done) ->
      thenStub.yields null
      aggregateService.command
        name: 'ExampleAggregate'
        id: 1
        methodName: 'doSomething'
      .then ->
        expect(exampleAggregateStub.generateDomainEvent.calledWith 'doSomething').to.be.true
        done()


    it 'should call saveAndTrigger on DomainEventService with the generated DomainEvents', (done) ->
      events = {}
      exampleAggregateStub.getDomainEvents.returns events
      thenStub.yields null
      aggregateService.command
        name: 'ExampleAggregate'
        id: 1
        methodName: 'doSomething'
      .then ->
        expect(domainEventService.saveAndTrigger.withArgs(events).calledOnce).to.be.true
        done()


    it 'should return the aggregateId', (done) ->
      thenStub.yields null
      aggregateService.command
        name: 'ExampleAggregate'
        id: 1
        methodName: 'doSomething'
      .then (aggregateId) ->
        expect(aggregateId).to.equal 1
        done()
