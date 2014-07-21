describe 'Context', ->
  Context = null

  class RepositoryMock

  HelperUnderscoreMock =
    extend: sandbox.stub()

  storeFake = null
  aggregateServiceStub = null
  eventricMock = null

  beforeEach ->
    collectionStub =
      remove: sandbox.stub().yields null

    storeFake =
      find: sandbox.stub().yields null, []
      collection: sandbox.stub().yields null, collectionStub

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
    eventricMock.require.withArgs('HelperAsync').returns eventric.require 'HelperAsync'
    mockery.registerMock 'eventric', eventricMock

    Context = eventric.require 'Context'


  describe '#initialize', ->

    it 'should throw an error if neither a global nor a custom event store was configured', ->
      context = new Context
      expect(context.initialize).to.throw Error


    it 'should instantiate all registered projections', (done) ->
      eventricMock.get.withArgs('store').returns storeFake
      context = new Context
      ProjectionStub = sandbox.stub()
      context.addProjection 'SomeProjection', ProjectionStub
      context.initialize =>
        expect(ProjectionStub).to.have.been.calledWithNew
        done()


    it 'should instantiate and initialize all registered adapters', (done) ->
      storeFake = {}
      eventricMock.get.withArgs('store').returns storeFake
      context = new Context
      AdapterFactory = sandbox.stub()
      context.addAdapter 'Adapter', AdapterFactory
      context.initialize =>
        expect(AdapterFactory).to.have.been.calledWithNew
        done()




  describe '#command', ->
    describe 'given the command has no registered handler', ->
      it 'should call the callback with a command not found error', (done) ->
        someContext = new Context
        someContext.set 'store', storeFake
        someContext.initialize =>

          command =
            name: 'doSomething'
            params:
              id: 42
              foo: 'bar'

          callback = sinon.spy()

          someContext.command command, callback
          expect(callback.calledWith sinon.match.instanceOf Error).to.be.true
          done()


    describe 'has a registered handler', ->
      it 'should execute the command handler', (done) ->
        commandStub = sandbox.stub()
        someContext = new Context
        someContext.set 'store', storeFake
        someContext.initialize =>
          someContext.addCommandHandler 'doSomething', commandStub

          command =
            name: 'doSomething'
            params:
              foo: 'bar'

          someContext.command command, ->
          expect(commandStub.calledWith command.params, sinon.match.func).to.be.true
          done()


  describe '#query', ->

    someContext = null

    beforeEach ->
      someContext = new Context
      someContext.set 'store', storeFake

    describe 'given the query has no read model matching the name', ->
      it 'should callback with an error', (done) ->
        someContext.initialize =>
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
        someContext.initialize =>
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

      beforeEach (done) ->
        someContext.addProjection 'Projection', Projection
        someContext.initialize =>
          done()


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