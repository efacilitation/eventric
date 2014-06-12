describe 'BoundedContext', ->
  mongoDbEventStoreMock = null
  class MongoDbEventStoreMock
    initialize: sandbox.stub().yields null
  class AggregateServiceMock
    command: sandbox.stub()
    create: sandbox.stub()

  domainEventServiceMock = null
  class DomainEventServiceMock
    constructor: ->
      domainEventServiceMock.apply this, arguments
    saveAndTrigger: sandbox.stub()
    on: sandbox.stub()

  aggregateServiceMock = null
  class AggregateServiceMock
    constructor: ->
      aggregateServiceMock.apply this, arguments

  class RepositoryMock

  HelperUnderscoreMock =
    extend: sandbox.stub()

  beforeEach ->
    mongoDbEventStoreMock = new MongoDbEventStoreMock
    eventricMock =
      require: sandbox.stub()
    eventricMock.require.withArgs('DomainEventService').returns DomainEventServiceMock
    eventricMock.require.withArgs('AggregateService').returns AggregateServiceMock
    eventricMock.require.withArgs('Repository').returns RepositoryMock
    eventricMock.require.withArgs('HelperUnderscore').returns HelperUnderscoreMock
    mockery.registerMock 'eventric', eventricMock
    mockery.registerMock 'eventric-store-mongodb', mongoDbEventStoreMock
    aggregateServiceMock = sandbox.stub()
    domainEventServiceMock = sandbox.stub()


  describe '#initialize', ->
    it 'should initialize the mongodb event store per default', ->
      boundedContext = eventric.boundedContext()
      boundedContext.initialize()
      expect(mongoDbEventStoreMock.initialize.calledOnce).to.be.true


    describe 'should initialize aggregateservice and domaineventservice', ->
      it 'with the mongodb event store per default', ->
        boundedContext = eventric.boundedContext()
        boundedContext.initialize()

        expect(aggregateServiceMock.calledWith sinon.match.instanceOf MongoDbEventStoreMock).to.be.true
        expect(domainEventServiceMock.calledWith sinon.match.instanceOf MongoDbEventStoreMock).to.be.true


      it 'with the custom event store if provided', ->
        customEventStoreMock = {}

        boundedContext = eventric.boundedContext()
        boundedContext.set 'store', customEventStoreMock
        boundedContext.initialize()

        expect(aggregateServiceMock.calledWith customEventStoreMock).to.be.true
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

        exampleBoundedContext.command command, ->
        expect(commandStub.calledWith command.params, sinon.match.func).to.be.true


  describe '#query', ->
    describe 'has no registered handler', ->
      it 'should call the callback with a command not found error', ->
        exampleBoundedContext = eventric.boundedContext()
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

        exampleBoundedContext.query query, ->

        expect(queryStub.calledWith query.params, sinon.match.func).to.be.true
