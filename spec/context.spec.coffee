describe 'Context', ->
  Context = null

  class RepositoryMock
  eventricMock = null

  beforeEach ->
    eventBusStub =
      subscribeToDomainEvent: sandbox.stub()

    mockery.registerMock './event_bus', sandbox.stub().returns eventBusStub
    mockery.registerMock './repository', RepositoryMock

    Context = require 'eventric/context'


  describe '#initialize', ->

    it 'should throw an error if neither a global nor a custom event store was configured', ->
      context = new Context
      expect(context.initialize).to.throw Error


    it 'should instantiate all registered projections', (done) ->
      context = new Context
      ProjectionStub = sandbox.stub()
      context.addProjection 'SomeProjection', ProjectionStub
      context.initialize =>
        expect(ProjectionStub).to.have.been.calledWithNew
        done()


    it 'should instantiate and initialize all registered adapters', (done) ->
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
        someContext.initialize =>

          callback = sinon.spy()

          someContext.command 'doSomething',
            id: 42
            foo: 'bar'
          , callback
          expect(callback.calledWith sinon.match.instanceOf Error).to.be.true
          done()


    describe 'has a registered handler', ->
      it 'should execute the command handler', (done) ->
        commandStub = sandbox.stub()
        someContext = new Context
        someContext.initialize =>
          someContext.addCommandHandler 'doSomething', commandStub

          params = foo: 'bar'
          someContext.command 'doSomething', params, ->
          expect(commandStub.calledWith params, sinon.match.func).to.be.true
          done()


  describe '#query', ->
    someContext = null
    beforeEach ->
      someContext = new Context

    describe 'given the query has no matching queryhandler', ->
      it 'should callback with an error', (done) ->
        someContext.initialize =>
          someContext.query 'getSomething'
          .catch (error) ->
            expect(error).to.be.an.instanceOf Error
            done()


    describe 'given the query has a matching queryhandler', ->
      it 'should call the queryhandler function', (done) ->
        queryStub = sandbox.stub().yields null, 'result'
        someContext.addQueryHandler 'getSomething', queryStub
        someContext.initialize =>
          someContext.query 'getSomething'
          .then (result) ->
            expect(result).to.equal 'result'
            expect(queryStub).to.have.been.calledWith
            done()
