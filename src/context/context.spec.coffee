describe.skip 'Context', ->
  Context = null

  class RepositoryMock
  eventBusStub = null
  eventricStub = null

  beforeEach ->
    eventBusStub =
      subscribeToDomainEvent: sandbox.stub()
      subscribeToDomainEventWithAggregateId: sandbox.stub()
      publishDomainEvent: sandbox.stub()

    eventric = require '..'
    eventricStub =
      get: -> {}
      log:
        debug: ->
      getStores: -> []
      publish: ->
      defaults: eventric.defaults
      eachSeries: eventric.eachSeriesprojectionService
      EventBus: sandbox.stub().returns eventBusStub
      Repository: RepositoryMock

    Context = require './'


  describe '#initialize', ->

    it 'should instantiate registered projections', ->
      context = new Context 'exampleContext', eventricStub
      class ProjectionStub
        stores: ['inmemory']
      context.addProjection 'SomeProjection', ProjectionStub
      context.initialize()
      .then ->
        context.getProjectionStore 'inmemory', 'SomeProjection', (err, projectionStore) ->
          expect(projectionStore).to.deep.equal {}


    it 'should instantiate and initialize all registered adapters', (done) ->
      context = new Context 'exampleContext', eventricStub
      AdapterFactory = sandbox.stub()
      context.addAdapter 'Adapter', AdapterFactory
      context.initialize ->
        expect(AdapterFactory).to.have.been.calledWithNew
        done()


  describe '#command', ->
    describe 'given the context was not initialized yet', ->
      it 'should callback with an error', (done) ->
        someContext = new Context 'exampleContext', eventricStub
        someContext.command 'getSomething'
        .catch (error) ->
          expect(error).to.be.an.instanceOf Error
          done()


    describe 'given the command has no registered handler', ->
      it 'should call the callback with a command not found error', (done) ->
        someContext = new Context 'exampleContext', eventricStub
        someContext.initialize ->

          callback = sinon.spy()

          someContext.command 'doSomething',
            id: 42
            foo: 'bar'
          .catch (error) ->
            expect(error).to.be.an.instanceof Error
            done()


    describe 'has a registered handler', ->
      it 'should execute the command handler', (done) ->
        commandStub = sandbox.stub()
        someContext = new Context 'exampleContext', eventricStub
        someContext.initialize ->
          someContext.addCommandHandler 'doSomething', commandStub

          params = foo: 'bar'
          someContext.command 'doSomething', params
          expect(commandStub.calledWith params, sinon.match.func).to.be.true
          done()


  describe '#query', ->
    someContext = null
    beforeEach ->
      someContext = new Context 'exampleContext', eventricStub

    describe 'given the context was not initialized yet', ->
      it 'should callback with an error', (done) ->
        someContext.query 'getSomething'
        .catch (error) ->
          expect(error).to.be.an.instanceOf Error
          done()


    describe 'given the query has no matching queryhandler', ->
      it 'should callback with an error', (done) ->
        someContext.initialize ->
          someContext.query 'getSomething'
          .catch (error) ->
            expect(error).to.be.an.instanceOf Error
            done()


    describe 'given the query has a matching queryhandler', ->
      it 'should call the queryhandler function', (done) ->
        queryStub = sandbox.stub().yields null, 'result'
        someContext.addQueryHandler 'getSomething', queryStub
        someContext.initialize ->
          someContext.query 'getSomething'
          .then (result) ->
            expect(result).to.equal 'result'
            expect(queryStub).to.have.been.calledWith
            done()


  describe '#emitDomainEvent', ->
    beforeEach (done) ->
      someContext = new Context 'ExampleContext', eventricStub
      someContext.defineDomainEvent 'WhatSoEver', ->
      someContext.initialize ->
        someContext.emitDomainEvent 'WhatSoEver'
        done()


    it 'should publish the DomainEvent on the EventBus', ->
      expect(eventBusStub.publishDomainEvent).to.have.been.called