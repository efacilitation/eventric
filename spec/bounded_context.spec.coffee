describe 'BoundedContext', ->
  BoundedContext = null

  class RepositoryMock

  HelperUnderscoreMock =
    extend: sandbox.stub()

  storeFake = null
  aggregateServiceStub = null
  eventricMock = null

  beforeEach ->
    storeFake =
      collection: sandbox.stub().yields null

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


  describe '#initialize', ->

    it 'should throw an error if neither a global nor a custom event store was configured', ->
      boundedContext = new BoundedContext
      expect(boundedContext.initialize).to.throw Error


    it 'should instantiate all registered read models', ->
      storeFake =
        collection: sandbox.stub().yields null, {}
      eventricMock.get.withArgs('store').returns storeFake
      boundedContext = new BoundedContext
      AggregateStub = sandbox.stub()
      boundedContext.addProjection 'Aggregate', AggregateStub
      boundedContext.initialize()
      expect(AggregateStub).to.have.been.calledWithNew


    it 'should instantiate and initialize all registered adapters', ->
      storeFake = {}
      eventricMock.get.withArgs('store').returns storeFake
      boundedContext = new BoundedContext
      AdapterFactory = sandbox.stub()
      boundedContext.addAdapter 'Adapter', AdapterFactory
      boundedContext.initialize()
      expect(AdapterFactory).to.have.been.calledWithNew




  describe '#command', ->
    describe 'given the command has no registered handler', ->
      it 'should call the callback with a command not found error', ->
        someContext = new BoundedContext
        someContext.set 'store', storeFake
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
        someContext.set 'store', storeFake
        someContext.initialize()
        someContext.addCommandHandler 'doSomething', commandStub

        command =
          name: 'doSomething'
          params:
            foo: 'bar'

        someContext.command command, ->
        expect(commandStub.calledWith command.params, sinon.match.func).to.be.true


  describe '#query', ->

    someContext = null

    beforeEach ->
      someContext = new BoundedContext
      someContext.set 'store', storeFake

    describe 'given the query has no read model matching the name', ->
      it 'should callback with an error', (done) ->
        someContext.initialize()
        someContext.query
          projectionName: 'Projection'
        .catch (error) ->
          expect(error).to.be.an.instanceOf Error
          expect(error.message).to.match /Given Projection Projection not found/
          done()


    describe 'given the query has no matching method on the read model', ->
      it 'should callback with an error', (done) ->
        class Projection
        someContext.addProjection 'Projection', Projection
        someContext.initialize()
        someContext.query
          projectionName: 'Projection'
          methodName: 'readSomething'
        .catch (error) ->
          expect(error).to.be.an.instanceOf Error
          expect(error.message).to.match /Given method readSomething not found/
          done()


    describe 'given the read model and the given method on it exists', ->
      class Projection
        readSomething: sinon.stub().yields null

      beforeEach ->
        someContext.addProjection 'Projection', Projection
        someContext.initialize()


      it 'should call the method passing in the method params', (done) ->
        params =
          foo: 'bar'
          bar: 'foo'
        someContext.query
          projectionName: 'Projection'
          methodName: 'readSomething'
          methodParams: params
        .then ->
          expect(Projection::readSomething).to.have.been.calledWith params
          done()


      it 'should callback with the result of the method', ->
        Projection::readSomething.yields null, 'result'
        someContext.query
          projectionName: 'Projection'
          methodName: 'readSomething'
        , (error, result) ->
          expect(result).to.equal 'result'