describe 'Context Feature', ->

  describe 'emitting a domain event', ->
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


  describe 'subscribing to all domain events', ->

    it 'should call the handler function with the domain event given the event is emitted', (done) ->
      exampleContext = eventric.context 'ExampleContext'
      exampleContext.defineDomainEvent 'SomeEvent', ->

      exampleContext.subscribeToAllDomainEvents (domainEvent) ->
        expect(domainEvent).to.be.ok
        done()

      exampleContext.initialize()
      .then ->
        exampleContext.emitDomainEvent 'SomeEvent', {}
      .catch done


  describe 'subscribing to a domain event by name', ->

    it 'should call the handler function with the domain event given the event is emitted', (done) ->
      exampleContext = eventric.context 'ExampleContext'
      exampleContext.defineDomainEvent 'SomeEvent', ->

      exampleContext.subscribeToDomainEvent 'SomeEvent', (domainEvent) ->
        expect(domainEvent).to.be.ok
        done()

      exampleContext.initialize()
      .then ->
        exampleContext.emitDomainEvent 'SomeEvent', {}
      .catch done


  describe 'subscribing to a domain event by name and aggregate id', ->

    it 'should call the handler function with the domain event given the event is emitted', (done) ->
      aggregateId = null
      exampleContext = eventric.context 'ExampleContext'

      exampleContext.defineDomainEvents
        'ExampleCreated': ->
        'ExampleModified': ->

      class ExampleAggregate
        create: ->
          @$emitDomainEvent 'ExampleCreated'

        modify: ->
          @$emitDomainEvent 'ExampleModified'

      exampleContext.addAggregate 'Example', ExampleAggregate

      exampleContext.addCommandHandlers
        CreateExample: (params) ->
          @$aggregate.create 'Example'
          .then (example) ->
            example.$save()

        ModifyExample: (params) ->
          @$aggregate.load 'Example', params.exampleId
          .then (example) ->
            example.modify params.exampleId
            example.$save()

      exampleContext.initialize()
      .then ->
        exampleContext.command 'CreateExample', {}
      .then (exampleId) ->
        exampleContext.subscribeToDomainEventWithAggregateId 'ExampleModified', exampleId, (domainEvent) ->
          expect(domainEvent).to.be.ok
          done()

        exampleContext.command 'ModifyExample',
          exampleId: exampleId
      .catch done


  describe 'adding a projection', ->

    it 'should call the initialize method of the projection', ->
      exampleContext = eventric.context 'exampleContext'

      class ProjectionStub
        initialize: sandbox.stub().yields()
      exampleContext.addProjection 'SomeProjection', ProjectionStub
      exampleContext.initialize()
      .then ->
        expect(ProjectionStub::initialize).to.have.been.called



  describe 'destroying a context', ->
    exampleContext = null

    beforeEach ->
      exampleContext = eventric.context 'ExampleContext'


    it 'should reject with an error given a command is executed afterwards', ->
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


    it 'should call destroy on the event bus', ->
      EventBus = require '../event_bus'
      sandbox.stub(EventBus::, 'destroy').returns Promise.resolve()
      exampleContext.initialize()
      .then ->
        exampleContext.destroy()
      .then ->
        expect(EventBus::destroy).to.have.been.called


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


    it 'should resolve correctly given previous command operations rejected', ->
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


    it 'should wait to resolve given a command which publishes a domain event which triggers another command with domain event', ->
      exampleContext.addAggregate 'Example', class Example
        create: ->
          @$emitDomainEvent 'ExampleCreated', {}


        modify: ->
          @$emitDomainEvent 'ExampleModified', {}
      exampleContext.defineDomainEvents
        ExampleCreated: ->
        ExampleModified: ->


      exampleContext.addCommandHandlers
        CreateExample: ->
          @$aggregate.create 'Example'
          .then (example) ->
            example.$save()


        ModifyExample: ({id}) ->
          @$aggregate.load 'Example', id
          .then (example) ->
            example.modify()
            example.$save()

      exampleContext.subscribeToDomainEvent 'ExampleCreated', (domainEvent) ->
        exampleContext.command 'ModifyExample', id: domainEvent.aggregate.id

      domainEventHandlerStub = sandbox.stub()
      exampleContext.subscribeToDomainEvent 'ExampleModified', domainEventHandlerStub

      exampleContext.initialize()
      .then ->
        exampleContext.command 'CreateExample', {}
        exampleContext.destroy()
      .then ->
        expect(domainEventHandlerStub).to.have.been.called