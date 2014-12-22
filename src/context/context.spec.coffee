describe 'Context', ->
  Context = null

  class RepositoryMock
  eventBusStub = null

  beforeEach ->
    eventBusStub =
      subscribeToDomainEvent: sandbox.stub()
      subscribeToDomainEventWithAggregateId: sandbox.stub()
      publishDomainEvent: sandbox.stub()

    Context = require './'


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
        someContext.initialize()
        .then ->

          callback = sinon.spy()

          someContext.command 'doSomething',
            id: 42
            foo: 'bar'
          .catch (error) ->
            expect(error).to.be.an.instanceof Error
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
        someContext.initialize()
        .then ->
          someContext.query 'getSomething'
          .catch (error) ->
            expect(error).to.be.an.instanceOf Error
            done()
