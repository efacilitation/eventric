describe 'AggregateService', ->
  DomainEvent = eventric.require 'DomainEvent'

  aggregateStubId = 1
  exampleAggregateRoot = null
  repositoryStub = null
  exampleAggregateStub = null
  AggregateService = null
  storeStub = null
  eventBusStub = null
  thenStub = null
  catchStub = null
  boundedContextStub = null
  beforeEach ->
    boundedContextStub =
      name: 'someContext'
    storeStub =
      save: sandbox.stub().yields null
    eventBusStub =
      publishDomainEvent: sandbox.stub()
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
      getDomainEvents: sandbox.stub().returns {}
    exampleAggregateStub = new ExampleAggregateStub

    repositoryStub =
      findById: sandbox.stub()

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
      aggregateService.initialize storeStub, eventBusStub, boundedContextStub
      aggregateService.registerAggregateRoot 'ExampleAggregate', {}


    it 'should return the aggregateId', (done) ->
      thenStub.yields null
      aggregateService.create
        name: 'ExampleAggregate'
      .then (aggregateId) ->
        expect(aggregateId).to.equal aggregateStubId
        done()


  describe '#command', ->
    aggregateService = null
    domainEvent = null

    beforeEach ->
      domainEvent = new DomainEvent
        name: 'SomethingHappened'
        aggregate:
          id: 1
          name: 'Example'

      exampleAggregateStub.getDomainEvents.returns [domainEvent]

      # findById should find something
      repositoryStub.findById.yields null, exampleAggregateStub

      # instantiate the command service
      aggregateService = new AggregateService
      aggregateService.initialize storeStub, eventBusStub, boundedContextStub
      aggregateService.registerAggregateRoot 'ExampleAggregate', {}


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


    it 'should tell the Store to save the DomainEvent', (done) ->
      thenStub.yields null
      aggregateService.command
        name: 'ExampleAggregate'
        id: 1
        methodName: 'doSomething'
      .then (aggregateId) ->
        expect(storeStub.save).to.have.been.calledWith 'someContext.events', domainEvent
        done()


    it 'should publish the domainevent on the eventbus', (done) ->
      thenStub.yields null
      aggregateService.command
        name: 'ExampleAggregate'
        id: 1
        methodName: 'doSomething'
      .then (aggregateId) ->
        expect(eventBusStub.publishDomainEvent).to.have.been.calledWith domainEvent
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
