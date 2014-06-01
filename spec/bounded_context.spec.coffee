describe 'BoundedContext', ->
  mongoDbEventStoreMock = null
  class MongoDbEventStoreMock
    initialize: sandbox.stub().yields null
  class CommandServiceMock
    commandAggregate: sandbox.stub()

  domainEventServiceMock = null
  class DomainEventServiceMock
    constructor: ->
      domainEventServiceMock.apply this, arguments
    saveAndTrigger: sandbox.stub()
    on: sandbox.stub()

  aggregateRepositoryMock = null
  class AggregateRepositoryMock
    constructor: ->
      aggregateRepositoryMock.apply this, arguments
    registerAggregateObj: sandbox.stub()

  class ReadAggregateRootMock
  class ReadAggregateRepositoryMock
    registerReadAggregateObj: sandbox.stub()

  beforeEach ->
    mongoDbEventStoreMock = new MongoDbEventStoreMock
    eventricMock =
      require: sandbox.stub()
    eventricMock.require.withArgs('CommandService').returns CommandServiceMock
    eventricMock.require.withArgs('DomainEventService').returns DomainEventServiceMock
    eventricMock.require.withArgs('AggregateRepository').returns AggregateRepositoryMock
    eventricMock.require.withArgs('ReadAggregateRoot').returns ReadAggregateRootMock
    eventricMock.require.withArgs('ReadAggregateRepository').returns ReadAggregateRepositoryMock
    mockery.registerMock 'eventric', eventricMock
    mockery.registerMock 'eventric-store-mongodb', mongoDbEventStoreMock
    aggregateRepositoryMock = sandbox.stub()
    domainEventServiceMock = sandbox.stub()


  describe '#initialize', ->
    it 'should initialize the mongodb event store per default', ->
      boundedContext = eventric.boundedContext()
      boundedContext.initialize()
      expect(mongoDbEventStoreMock.initialize.calledOnce).to.be.true


    it 'should register the configured aggregates at the aggregateRepository', ->
      boundedContext = eventric.boundedContext()

      class FooAggregateMock
      class BarAggregateMock
      boundedContext.addAggregate 'Foo', FooAggregateMock
      boundedContext.addAggregate 'Bar', BarAggregateMock

      boundedContext.initialize()

      expect(AggregateRepositoryMock::registerAggregateObj.calledWith 'Foo', FooAggregateMock).to.be.true
      expect(AggregateRepositoryMock::registerAggregateObj.calledWith 'Bar', BarAggregateMock).to.be.true


    it 'should instantiate and save the configured read aggregate repositories', ->
      boundedContext = eventric.boundedContext()

      class FooReadAggregateRepository
      class BarReadAggregateRepository
      boundedContext.addReadAggregateRepository 'Foo', FooReadAggregateRepository
      boundedContext.addReadAggregateRepository 'Bar', BarReadAggregateRepository

      boundedContext.initialize()

      expect((boundedContext.getReadAggregateRepository 'Foo') instanceof FooReadAggregateRepository).to.be.true
      expect((boundedContext.getReadAggregateRepository 'Bar') instanceof BarReadAggregateRepository).to.be.true


    describe 'should initialize aggregaterepository and domaineventservice', ->
      it 'with the mongodb event store per default', ->
        boundedContext = eventric.boundedContext()
        boundedContext.initialize()

        expect(aggregateRepositoryMock.calledWith sinon.match.instanceOf MongoDbEventStoreMock).to.be.true
        expect(domainEventServiceMock.calledWith sinon.match.instanceOf MongoDbEventStoreMock).to.be.true


      it 'with the custom event store if provided', ->
        customEventStoreMock = {}

        boundedContext = eventric.boundedContext()
        boundedContext.set 'store', customEventStoreMock
        boundedContext.initialize()

        expect(aggregateRepositoryMock.calledWith customEventStoreMock).to.be.true
        expect(domainEventServiceMock.calledWith customEventStoreMock).to.be.true


  describe '#command', ->
    describe 'given the command has no registered handler', ->
      it 'should call the callback with a command not found error', ->
        boundedContext = eventric.boundedContext()
        boundedContext.initialize()

        command =
          name: 'doSomething'
          params:
            id: 42
            foo: 'bar'

        callback = sinon.spy()

        boundedContext.command command, callback
        expect(callback.calledWith sinon.match.instanceOf Error).to.be.true


    describe 'has a registered handler', ->
      it 'should execute the command handler', ->
        commandStub = sandbox.stub()
        exampleBoundedContext = eventric.boundedContext()
        exampleBoundedContext.addCommand 'doSomething', commandStub
        exampleBoundedContext.initialize()

        command =
          name: 'doSomething'
          params:
            foo: 'bar'

        callback = ->

        exampleBoundedContext.command command, callback

        expect(commandStub.calledWith command.params, callback).to.be.true


  describe '#query', ->
    describe 'has no registered handler', ->
      it 'should call the callback with a command not found error', ->
        exampleBoundedContext = eventric.boundedContext()
        class FooReadAggregateRepository
          find: sandbox.stub()
        exampleBoundedContext.addReadAggregateRepository 'Aggregate', FooReadAggregateRepository
        exampleBoundedContext.initialize()

        query =
          name: 'findSomething'
          params:
            foo: 'bar'

        callback = sinon.spy()

        exampleBoundedContext.query query, callback
        expect(callback.calledWith sinon.match.instanceOf Error).to.be.true


    describe 'has a registered handler', ->
      it 'should execute the query handler', ->
        exampleBoundedContext = eventric.boundedContext()
        queryStub = sandbox.stub()
        exampleBoundedContext.addQuery 'findSomething', queryStub
        exampleBoundedContext.initialize()

        query =
          name: 'findSomething'
          params:
            id: 42
            foo: 'bar'
        callback = ->

        exampleBoundedContext.query query, callback

        expect(queryStub.calledWith query.params, callback).to.be.true


  describe '#onDomainEvent', ->
    it 'should delegate the handler registration to the domain event service', ->
      exampleBoundedContext = eventric.boundedContext()
      exampleBoundedContext.initialize()

      eventName = 'Aggregate:method'
      eventHandler = ->
      exampleBoundedContext.onDomainEvent eventName, eventHandler

      expect(DomainEventServiceMock::on.calledWith eventName, eventHandler).to.be.true
