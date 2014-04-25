describe 'BoundedContext', ->
  expect         = require 'expect.js'
  sinon          = require 'sinon'
  mockery        = require 'mockery'
  eventric       = require 'eventric'
  sandbox        = sinon.sandbox.create()


  class MongoDbEventStoreMock
    initialize: sandbox.stub().yields null
  class CommandServiceMock
    commandAggregate: sandbox.stub()

  # TODO refactor me
  domainEventServiceMock = null
  class DomainEventServiceMock
    constructor: ->
      domainEventServiceMock.apply this, arguments
    saveAndTrigger: sandbox.stub()
    on: sandbox.stub()

  # TODO refactor me
  aggregateRepositoryMock = null
  class AggregateRepositoryMock
    constructor: ->
      aggregateRepositoryMock.apply this, arguments
    registerClass: sandbox.stub()

  before ->
    mockery.enable
      warnOnReplace: true
      warnOnUnregistered: false


  beforeEach ->
    eventricMock = sandbox.stub()
    eventricMock.withArgs('CommandService').returns CommandServiceMock
    eventricMock.withArgs('DomainEventService').returns DomainEventServiceMock
    eventricMock.withArgs('AggregateRepository').returns AggregateRepositoryMock
    mockery.registerMock 'eventric', eventricMock
    mockery.registerMock 'eventric-store-mongodb', MongoDbEventStoreMock
    aggregateRepositoryMock = sandbox.stub()
    domainEventServiceMock = sandbox.stub()


  afterEach ->
    mockery.deregisterAll()
    sandbox.restore()


  after ->
    mockery.disable()


  describe '#initialize', ->
    it 'should initialize the mongodb event store per default', ->
      BoundedContext = eventric 'BoundedContext'
      boundedContext = new BoundedContext
      boundedContext.initialize()

      expect(MongoDbEventStoreMock::initialize.calledOnce).to.be.ok()


    describe 'should initialize aggregaterepository and domaineventservice', ->
      it 'with the mongodb event store per default', ->
        BoundedContext = eventric 'BoundedContext'
        boundedContext = new BoundedContext
        boundedContext.initialize()

        expect(aggregateRepositoryMock.calledWith sinon.match.instanceOf MongoDbEventStoreMock).to.be.ok()
        expect(domainEventServiceMock.calledWith sinon.match.instanceOf MongoDbEventStoreMock).to.be.ok()


      it 'with the custom event store if provided', ->
        customEventStoreMock = {}

        BoundedContext = eventric 'BoundedContext'
        boundedContext = new BoundedContext
        boundedContext.initialize customEventStoreMock

        expect(aggregateRepositoryMock.calledWith customEventStoreMock).to.be.ok()
        expect(domainEventServiceMock.calledWith customEventStoreMock).to.be.ok()


    it 'should register the configured aggregates at the aggregateRepository', ->
      BoundedContext = eventric 'BoundedContext'

      class FooAggregateMock
      class BarAggregateMock
      class ExampleBoundedContext extends BoundedContext
        aggregates:
          'Foo': FooAggregateMock
          'Bar': BarAggregateMock

      boundedContext = new ExampleBoundedContext
      boundedContext.initialize()

      expect(AggregateRepositoryMock::registerClass.calledWith 'Foo', FooAggregateMock).to.be.ok()
      expect(AggregateRepositoryMock::registerClass.calledWith 'Bar', BarAggregateMock).to.be.ok()


    it 'should instantiate and save the configured read aggregate repositories', ->
      BoundedContext = eventric 'BoundedContext'

      class FooReadAggregateRepository
      class BarReadAggregateRepository
      class ExampleBoundedContext extends BoundedContext
        readAggregateRepositories:
          'Foo': FooReadAggregateRepository
          'Bar': BarReadAggregateRepository

      boundedContext = new ExampleBoundedContext
      boundedContext.initialize()

      expect((boundedContext.getReadAggregateRepository 'Foo') instanceof FooReadAggregateRepository).to.be.ok()
      expect((boundedContext.getReadAggregateRepository 'Bar') instanceof BarReadAggregateRepository).to.be.ok()


    it 'should inject the command service into the application services ', ->
      exampleApplicationService = {}
      BoundedContext = eventric 'BoundedContext'
      class ExampleBoundedContext extends BoundedContext
        applicationServices: [
          exampleApplicationService
        ]
      exampleBoundedContext = new ExampleBoundedContext
      exampleBoundedContext.initialize()

      expect(exampleApplicationService.commandService instanceof CommandServiceMock).to.be.ok()


  describe '#command', ->
    describe 'given the command has no registered handler', ->
      it 'should call the command service with the correct parameters', ->
        BoundedContext = eventric 'BoundedContext'
        boundedContext = new BoundedContext
        boundedContext.initialize()

        command =
          name: 'Aggregate:doSomething'
          id: 42
          params:
            foo: 'bar'

        boundedContext.command command
        expect(CommandServiceMock::commandAggregate.calledWith 'Aggregate', command.id, 'doSomething', command.params).to.be.ok()


    describe 'has a registered handler', ->
      it 'should execute the command handler', ->
        exampleApplicationService =
          commands:
            'Aggregate:doSomething': 'accountDoSomething'
          accountDoSomething: sandbox.stub()

        BoundedContext = eventric 'BoundedContext'
        class ExampleBoundedContext extends BoundedContext
          applicationServices: [
            exampleApplicationService
          ]

        exampleBoundedContext = new ExampleBoundedContext
        exampleBoundedContext.initialize()

        command =
          name: 'Aggregate:doSomething'
          params:
            foo: 'bar'
        exampleBoundedContext.command command

        expect(exampleApplicationService.accountDoSomething.calledWith command.params).to.be.ok()


  describe '#query', ->
    describe 'has no registered handler', ->
      it 'should execute the query directly on the correct read aggregate repository', ->
        BoundedContext = eventric 'BoundedContext'
        class FooReadAggregateRepository
          findById: sandbox.stub()
        class ExampleBoundedContext extends BoundedContext
          readAggregateRepositories:
            'Aggregate': FooReadAggregateRepository
        exampleBoundedContext = new ExampleBoundedContext
        exampleBoundedContext.initialize()

        query =
          name: 'Aggregate:findById'
          id: 42

        exampleBoundedContext.query query

        expect(FooReadAggregateRepository::findById.calledWith query.id).to.be.ok()


    describe 'has a registered handler', ->
      it 'should execute the query handler', ->
        BoundedContext = eventric 'BoundedContext'
        exampleApplicationService =
          queries:
            'customQuery': 'customQueryMethod'
          customQueryMethod: sandbox.stub()

        class ExampleBoundedContext extends BoundedContext
          applicationServices: [
            exampleApplicationService
          ]
        exampleBoundedContext = new ExampleBoundedContext
        exampleBoundedContext.initialize()

        query =
          name: 'customQuery'
          params:
            foo: 'bar'
        exampleBoundedContext.query query

        expect(exampleApplicationService.customQueryMethod.calledWith query.params).to.be.ok()


  describe 'onDomainEvent', ->
    it 'should delegate the handler registration to the domain event service', ->
      BoundedContext = eventric 'BoundedContext'
      class ExampleBoundedContext extends BoundedContext
      exampleBoundedContext = new ExampleBoundedContext
      exampleBoundedContext.initialize()

      eventName = 'Aggregate:method'
      eventHandler = ->
      exampleBoundedContext.onDomainEvent eventName, eventHandler

      expect(DomainEventServiceMock::on.calledWith eventName, eventHandler).to.be.ok()
