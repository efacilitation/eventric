describe 'Context', ->
  Context = null

  eventBusStub = null

  beforeEach ->
    EventBus = require '../event_bus'

    eventBusStub = new EventBus eventricStub
    sandbox.stub eventBusStub, 'subscribeToDomainEvent'
    sandbox.stub eventBusStub, 'subscribeToDomainEventWithAggregateId'
    sandbox.stub eventBusStub, 'publishDomainEvent'
    sandbox.stub(eventBusStub, 'destroy').returns new Promise (resolve) -> resolve()

    eventricStub.EventBus = -> eventBusStub

    Context = require './'


  describe '#command', ->
    describe 'given the context was not initialized yet', ->
      it 'should callback with an error including the context name and command name', (done) ->
        someContext = new Context 'ExampleContext', eventricStub
        someContext.command 'DoSomething'
        .catch (error) ->
          expect(error).to.be.an.instanceOf Error
          expect(error.message).to.contain 'ExampleContext'
          expect(error.message).to.contain 'DoSomething'
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
      someContext = new Context 'ExampleContext', eventricStub

    describe 'given the context was not initialized yet', ->
      it 'should callback with an error including the context name and command name', (done) ->
        someContext.query 'getSomething'
        .catch (error) ->
          expect(error).to.be.an.instanceOf Error
          expect(error.message).to.contain 'ExampleContext'
          expect(error.message).to.contain 'getSomething'
          done()


    describe 'given the query has no matching queryhandler', ->
      it 'should callback with an error', (done) ->
        someContext.initialize()
        .then ->
          someContext.query 'getSomething'
          .catch (error) ->
            expect(error).to.be.an.instanceOf Error
            done()


  describe '#destroy', ->
    someContext = null

    beforeEach ->
      someContext = new Context 'ExampleContext', eventricStub


    it 'should call destroy on the event bus', ->
      someContext.destroy()
      expect(eventBusStub.destroy).to.have.been.called


    it 'should reject with an error given command is called afterwards', ->
      someContext.addCommandHandlers DoSomething: ->
      commandParams = foo: 'bar'
      someContext.destroy()
      .then ->
        someContext.command 'DoSomething', commandParams
      .catch (error) ->
        expect(error).to.be.an.instanceOf Error
        expect(error.message).to.contain 'command'
        expect(error.message).to.contain 'DoSomething'
        expect(error.message).to.contain 'ExampleContext'
        expect(error.message).to.match /"foo"\:\s*"bar"/


    it 'should reject with an error given emitDomainEvent is called afterwards', ->
      someContext.defineDomainEvent SomethingHappened: ->
      someContext.destroy()
      .then ->
        someContext.emitDomainEvent 'SomethingHappened', {}
      .catch (error) ->
        expect(error).to.be.an.instanceOf Error
        expect(error.message).to.contain 'emit domain event'
        expect(error.message).to.contain 'SomethingHappened'
        expect(error.message).to.contain 'ExampleContext'
