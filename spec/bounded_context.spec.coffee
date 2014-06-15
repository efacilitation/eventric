describe 'BoundedContext', ->
  BoundedContext = null

  class RepositoryMock

  HelperUnderscoreMock =
    extend: sandbox.stub()

  storeStub = null
  domainEventServiceStub = null
  aggregateServiceStub = null

  beforeEach ->
    storeStub = sandbox.stub()

    domainEventServiceStub =
      initialize: sandbox.stub()

    aggregateServiceStub =
      initialize: sandbox.stub()

    eventricMock =
      require: sandbox.stub()
    eventricMock.require.withArgs('DomainEventService').returns sandbox.stub().returns domainEventServiceStub
    eventricMock.require.withArgs('AggregateService').returns sandbox.stub().returns aggregateServiceStub
    eventricMock.require.withArgs('Repository').returns RepositoryMock
    eventricMock.require.withArgs('HelperUnderscore').returns HelperUnderscoreMock
    mockery.registerMock 'eventric', eventricMock

    BoundedContext = eventric.require 'BoundedContext'


  it 'should initialize aggregateservice and domaineventservice with the given event store', ->
    someContext = new BoundedContext
    someContext.initialize 'someContext', storeStub

    expect(aggregateServiceStub.initialize.calledWith storeStub).to.be.true
    expect(domainEventServiceStub.initialize.calledWith storeStub).to.be.true


  describe '#command', ->
    describe 'given the command has no registered handler', ->
      it 'should call the callback with a command not found error', ->
        someContext = new BoundedContext
        someContext.initialize 'someContext', storeStub

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
        someContext.initialize 'someContext', storeStub
        someContext.addCommand 'doSomething', commandStub

        command =
          name: 'doSomething'
          params:
            foo: 'bar'

        someContext.command command, ->
        expect(commandStub.calledWith command.params, sinon.match.func).to.be.true


  describe '#query', ->
    describe 'has no registered handler', ->
      it 'should call the callback with a command not found error', ->
        someContext = new BoundedContext
        someContext.initialize 'someContext', storeStub

        query =
          name: 'findSomething'
          params:
            foo: 'bar'

        callback = sinon.spy()

        someContext.query query, callback
        expect(callback.calledWith sinon.match.instanceOf Error).to.be.true


    describe 'has a registered handler', ->
      it 'should execute the query handler', ->
        someContext = new BoundedContext
        someContext.initialize 'someContext', storeStub
        queryStub = sandbox.stub()
        someContext.addQuery 'findSomething', queryStub

        query =
          name: 'findSomething'
          params:
            id: 42
            foo: 'bar'

        someContext.query query, ->

        expect(queryStub.calledWith query.params, sinon.match.func).to.be.true
