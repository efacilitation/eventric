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
    registerClass: sandbox.stub()


  beforeEach ->
    mongoDbEventStoreMock = new MongoDbEventStoreMock
    eventricMock =
      require: sandbox.stub()
    eventricMock.require.withArgs('CommandService').returns CommandServiceMock
    eventricMock.require.withArgs('DomainEventService').returns DomainEventServiceMock
    eventricMock.require.withArgs('AggregateRepository').returns AggregateRepositoryMock
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
      boundedContext.add 'aggregate', 'Foo', FooAggregateMock
      boundedContext.add 'aggregates',
        'Bar': BarAggregateMock

      boundedContext.initialize()

      expect(AggregateRepositoryMock::registerClass.calledWith 'Foo', FooAggregateMock).to.be.true
      expect(AggregateRepositoryMock::registerClass.calledWith 'Bar', BarAggregateMock).to.be.true


    it 'should instantiate and save the configured read aggregate repositories', ->
      boundedContext = eventric.boundedContext()

      class FooReadAggregateRepository
      class BarReadAggregateRepository
      boundedContext.add 'repository', 'Foo', FooReadAggregateRepository
      boundedContext.add 'repositories',
        'Bar': BarReadAggregateRepository

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


    describe 'processing application services', ->
      exampleApplicationService = null
      exampleBoundedContext = null

      beforeEach ->
        exampleApplicationService = {}
        exampleBoundedContext = eventric.boundedContext()
        exampleBoundedContext.add 'application', exampleApplicationService


      it 'should call initialize on the application service if available', ->
        exampleApplicationService.initialize = sinon.spy()
        exampleBoundedContext.initialize()
        expect(exampleApplicationService.initialize.calledOnce).to.be.true


      describe 'injections', ->

        beforeEach ->
          exampleBoundedContext.initialize()


        it 'should inject the command service into the application services ', ->
          expect(exampleApplicationService.commandService instanceof CommandServiceMock).to.be.true


        it 'should inject the getReadAggregateRepository function into the application services', ->
          expect(exampleApplicationService.getReadAggregateRepository).to.be.a 'function'


        it 'should inject the onDomainEvent function into the application service', ->
          expect(exampleApplicationService.onDomainEvent).to.be.a 'function'


  describe '#command', ->
    describe 'given the command has no registered handler', ->
      it 'should call the command service with the correct parameters', ->
        boundedContext = eventric.boundedContext()
        boundedContext.initialize()

        command =
          name: 'Aggregate:doSomething'
          id: 42
          params:
            foo: 'bar'

        callback = ->

        boundedContext.command command, callback
        expect(CommandServiceMock::commandAggregate.calledWith 'Aggregate', command.id, 'doSomething', command.params, callback).to.be.true


    describe 'has a registered handler', ->
      it 'should execute the command handler', ->
        exampleApplicationService =
          commands:
            'Aggregate:doSomething': 'accountDoSomething'
          accountDoSomething: sandbox.stub()

        exampleBoundedContext = eventric.boundedContext()
        exampleBoundedContext.add 'application', exampleApplicationService
        exampleBoundedContext.initialize()

        command =
          name: 'Aggregate:doSomething'
          params:
            foo: 'bar'

        callback = ->

        exampleBoundedContext.command command, callback

        expect(exampleApplicationService.accountDoSomething.calledWith command.params, callback).to.be.true


  describe '#query', ->
    describe 'has no registered handler', ->
      it 'should execute the query directly on the correct read aggregate repository', ->
        exampleBoundedContext = eventric.boundedContext()
        class FooReadAggregateRepository
          find: sandbox.stub()
        exampleBoundedContext.add 'repository', 'Aggregate', FooReadAggregateRepository
        exampleBoundedContext.initialize()

        query =
          name: 'Aggregate:find'
          id: 42
          params:
            foo: 'bar'
        callback = ->

        exampleBoundedContext.query query, callback

        expect(FooReadAggregateRepository::find.calledWith query.id, query.params, callback).to.be.true


    describe 'has no registered handler for Aggregate:findById', ->
      it 'should execute findById directly on the correct read aggregate repository without passing the params', ->
        exampleBoundedContext = eventric.boundedContext()
        class FooReadAggregateRepository
          findById: sandbox.stub()
        exampleBoundedContext.add 'repository', 'Aggregate', FooReadAggregateRepository
        exampleBoundedContext.initialize()

        query =
          name: 'Aggregate:findById'
          id: 42
        callback = ->

        exampleBoundedContext.query query, callback

        expect(FooReadAggregateRepository::findById.calledWithExactly query.id, callback).to.be.true


    describe 'has a registered handler', ->
      it 'should execute the query handler', ->
        exampleBoundedContext = eventric.boundedContext()
        exampleApplicationService =
          queries:
            'customQuery': 'customQueryMethod'
          customQueryMethod: sandbox.stub()
        exampleBoundedContext.add 'application', exampleApplicationService
        exampleBoundedContext.initialize()

        query =
          name: 'customQuery'
          params:
            foo: 'bar'
        callback = ->

        exampleBoundedContext.query query, callback

        expect(exampleApplicationService.customQueryMethod.calledWith query.params, callback).to.be.true


  describe '#onDomainEvent', ->
    it 'should delegate the handler registration to the domain event service', ->
      exampleBoundedContext = eventric.boundedContext()
      exampleBoundedContext.initialize()

      eventName = 'Aggregate:method'
      eventHandler = ->
      exampleBoundedContext.onDomainEvent eventName, eventHandler

      expect(DomainEventServiceMock::on.calledWith eventName, eventHandler).to.be.true
