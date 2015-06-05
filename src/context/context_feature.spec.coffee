describe 'Context Feature', ->

  describe '#emitDomainEvent', ->

    describe 'given the domain event is registered on the context', ->

      exampleContext = null

      beforeEach ->
        exampleContext = eventric.context 'ExampleContext'
        exampleContext.defineDomainEvent 'SomeEvent', ->

      it 'should publish the domain event', (done) ->
        exampleContext.subscribeToDomainEvent 'SomeEvent', (domainEvent) ->
          expect(domainEvent).to.be.ok
          done()
        exampleContext.initialize()
        .then ->
          exampleContext.emitDomainEvent 'SomeEvent', {}
        .catch done


      it 'should save the domain event', (done) ->
        exampleContext.initialize()
        .then ->
          exampleContext.emitDomainEvent 'SomeEvent', {}
        .then ->
          exampleContext.getDomainEventsStore().findDomainEventsByName 'SomeEvent', (error, domainEvents) ->
            expect(domainEvents.length).to.equal 1
            expect(domainEvents[0].name).to.equal 'SomeEvent'
            done()
        .catch done


  describe '#destroy', ->
    exampleContext = null

    beforeEach ->
      exampleContext = eventric.context 'ExampleContext'


    it 'should wait to resolve given there are ongoing command operations', ->
      commandSpy = sandbox.spy()
      exampleContext.addCommandHandlers
        DoSomething: (params) ->
          new Promise (resolve) ->
            setTimeout ->
              commandSpy params
              resolve()
            , 15

      exampleContext.initialize()
      .then ->
        exampleContext.command 'DoSomething', call: 1
        exampleContext.command 'DoSomething', call: 2
        exampleContext.destroy()
      .then ->
        expect(commandSpy).to.have.been.calledWith call: 1
        expect(commandSpy).to.have.been.calledWith call: 2


    it 'should wait to resolve given there are ongoing emit domain event operations', ->
      domainEventHandlerSpy = sandbox.spy()
      exampleContext.defineDomainEvent 'SomethingHappened', ->
      exampleContext.initialize()
      .then ->
        exampleContext.subscribeToDomainEvent 'SomethingHappened', domainEventHandlerSpy
        exampleContext.emitDomainEvent 'SomethingHappened', {}
        exampleContext.emitDomainEvent 'SomethingHappened', {}
        exampleContext.destroy()
      .then ->
        expect(domainEventHandlerSpy.callCount).to.equal 2


    it 'should correctly resolve given previous command operations rejected', ->
      commandSpy = sandbox.spy()
      exampleContext.addCommandHandlers
        DoSomething: (params) ->
          new Promise (resolve, reject) ->
            commandSpy params
            reject()
      exampleContext.initialize()
      .then ->
        exampleContext.command 'DoSomething', {}
        exampleContext.destroy()
      .then ->
        expect(commandSpy).to.have.been.called


    it 'should call destroy on the event bus', ->
      EventBus = require '../event_bus'
      sandbox.stub(EventBus::, 'destroy').returns Promise.resolve()
      exampleContext.initialize()
      .then ->
        exampleContext.destroy()
      .then ->
        expect(EventBus::destroy).to.have.been.called


    it 'should reject with an error given command is called afterwards', ->
      exampleContext.addCommandHandlers DoSomething: ->
      commandParams = foo: 'bar'
      exampleContext.destroy()
      .then ->
        exampleContext.command 'DoSomething', commandParams
      .catch (error) ->
        expect(error).to.be.an.instanceOf Error
        expect(error.message).to.contain 'command'
        expect(error.message).to.contain 'DoSomething'
        expect(error.message).to.contain 'ExampleContext'
        expect(error.message).to.match /"foo"\:\s*"bar"/


    it 'should reject with an error given emitDomainEvent is called afterwards', ->
      exampleContext.defineDomainEvent SomethingHappened: ->
      exampleContext.destroy()
      .then ->
        exampleContext.emitDomainEvent 'SomethingHappened', {}
      .catch (error) ->
        expect(error).to.be.an.instanceOf Error
        expect(error.message).to.contain 'emit domain event'
        expect(error.message).to.contain 'SomethingHappened'
        expect(error.message).to.contain 'ExampleContext'
