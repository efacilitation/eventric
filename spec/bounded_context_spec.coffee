describe 'BoundedContext', ->
  expect         = require 'expect.js'
  sinon          = require 'sinon'
  mockery        = require 'mockery'
  eventric       = require 'eventric'

  beforeEach ->
    mockery.enable
      warnOnReplace: false
      warnOnUnregistered: false

    class eventricComponent
      initialize: sinon.stub().yields false
      registerClass: sinon.stub()
      registerServiceHandler: sinon.stub()
    class CommandServiceMock
      commandAggregate: sinon.stub()
    class AggregateRepositoryMock
      registerClass: sinon.stub()
    eventricMock = sinon.stub()
    eventricMock.returns eventricComponent
    eventricMock.withArgs('CommandService').returns CommandServiceMock
    eventricMock.withArgs('AggregateRepository').returns AggregateRepositoryMock
    mockery.registerMock 'eventric', eventricMock


  afterEach ->
    mockery.deregisterAll()
    mockery.disable()


  describe '#initialize', ->
    it 'should configure required eventric components', ->
      BoundedContext = eventric 'BoundedContext'
      class ExampleBoundedContext extends BoundedContext

      boundedContext = new ExampleBoundedContext
      boundedContext.initialize()
      expect(boundedContext.aggregateRepository).to.be.ok()
      expect(boundedContext.commandService).to.be.ok()
      expect(boundedContext.domainEventService).to.be.ok()


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

      expect(boundedContext.aggregateRepository.registerClass.calledWith 'Foo', FooAggregateMock).to.be.ok()
      expect(boundedContext.aggregateRepository.registerClass.calledWith 'Bar', BarAggregateMock).to.be.ok()


    it 'should instantiate and save the configured read aggregate repositories', ->
      BoundedContext = eventric 'BoundedContext'

      class FooReadAggregateRepository
      class BarReadAggregateRepository
      class ExampleBoundedContext extends BoundedContext
        readAggregateRepositories:
          'ReadFoo': FooReadAggregateRepository
          'ReadBar': BarReadAggregateRepository

      boundedContext = new ExampleBoundedContext
      boundedContext.initialize()

      expect((boundedContext.getReadAggregateRepository 'ReadFoo') instanceof FooReadAggregateRepository).to.be.ok()
      expect((boundedContext.getReadAggregateRepository 'ReadBar') instanceof BarReadAggregateRepository).to.be.ok()


  describe '#command', ->
    describe 'given the command has no registered handler', ->
      it 'should call the command service with the correct parameters', ->
        BoundedContext = eventric 'BoundedContext'
        boundedContext = new BoundedContext
        boundedContext.initialize()
        id = 42
        params = {foo: 'bar'}
        boundedContext.command 'Aggregate:function', id, params
        expect(boundedContext.commandService.commandAggregate.calledWith 'Aggregate', id, 'function', params).to.be.ok()


    describe 'has a registered handler', ->
      it 'should execute the command handler'


  describe '#query', ->
    describe 'has no registered handler', ->
      it 'should execute the query directly on the repository'


    describe 'has a registered handler', ->
      it 'should execute the query handler'
