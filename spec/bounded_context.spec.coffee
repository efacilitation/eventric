describe 'BoundedContext', ->
  BoundedContext = null

  class RepositoryMock

  HelperUnderscoreMock =
    extend: sandbox.stub()

  storeStub = null
  aggregateServiceStub = null
  eventricMock = null

  beforeEach ->
    storeStub = sandbox.stub()

    eventBusStub =
      subscribeToDomainEvent: sandbox.stub()

    aggregateServiceStub =
      initialize: sandbox.stub()

    eventricMock =
      require: sandbox.stub()
      get: sandbox.stub()
    eventricMock.require.withArgs('AggregateService').returns sandbox.stub().returns aggregateServiceStub
    eventricMock.require.withArgs('EventBus').returns sandbox.stub().returns eventBusStub
    eventricMock.require.withArgs('Repository').returns RepositoryMock
    eventricMock.require.withArgs('HelperUnderscore').returns HelperUnderscoreMock
    mockery.registerMock 'eventric', eventricMock

    BoundedContext = eventric.require 'BoundedContext'


  it 'should initialize aggregateservice with the custom event store if configured', ->
    boundedContext = new BoundedContext
    boundedContext.set 'store', storeStub
    boundedContext.initialize()
    expect(aggregateServiceStub.initialize.calledWith storeStub).to.be.true


  it 'should initialize aggregateservice with the global event store if configured', ->
    globalStoreStub = sandbox.stub()
    eventricMock.get.withArgs('store').returns globalStoreStub
    boundedContext = new BoundedContext
    boundedContext.initialize()
    expect(aggregateServiceStub.initialize.calledWith globalStoreStub).to.be.true


  it 'should throw an error if neither a global nor a custom event store was configured', ->
    boundedContext = new BoundedContext
    expect(boundedContext.initialize).to.throw Error


  describe '#command', ->
    describe 'given the command has no registered handler', ->
      it 'should call the callback with a command not found error', ->
        someContext = new BoundedContext
        someContext.set 'store', storeStub
        someContext.initialize()

        command =
          name: 'doSomething'
          params:
            id: 42
            foo: 'bar'

        callback = sinon.spy()

        someContext.command command, callback
        expect(callback.calledWith sinon.match.instanceOf Error).to.be.true


    describe 'has a registered handler', ->
      it 'should execute the command handler', ->
        commandStub = sandbox.stub()
        someContext = new BoundedContext
        someContext.set 'store', storeStub
        someContext.initialize()
        someContext.addCommandHandler 'doSomething', commandStub

        command =
          name: 'doSomething'
          params:
            foo: 'bar'

        someContext.command command, ->
        expect(commandStub.calledWith command.params, sinon.match.func).to.be.true
