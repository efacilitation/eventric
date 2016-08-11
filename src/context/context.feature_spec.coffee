describe 'Context Feature', ->

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
      return


  describe 'adding projections', ->

    it 'should call the initialize method of the projection', ->
      exampleContext = eventric.context 'exampleContext'

      projectionObject =
        initialize: sandbox.stub().yields()
      exampleContext.addProjection projectionObject
      exampleContext.initialize()
      .then ->
        expect(projectionObject.initialize).to.have.been.called


  it 'should correctly call the initialize methods of multiple projections', ->
    exampleContext = eventric.context 'exampleContext'

    firstProjection = initialize: sandbox.stub().yields()
    secondProjection = initialize: sandbox.stub().yields()
    exampleContext.addProjection firstProjection
    exampleContext.addProjection secondProjection

    exampleContext.initialize()
    .then ->
      expect(firstProjection.initialize).to.have.been.called
      expect(secondProjection.initialize).to.have.been.called


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


    it 'should call destroy on the event bus', ->
      EventBus = require 'eventric/event_bus'
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


    it 'should wait to resolve given a command which publishes a domain event \
    which triggers another command with domain event', ->
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
