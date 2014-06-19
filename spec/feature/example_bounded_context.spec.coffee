eventric = require 'eventric'

describe 'Example BoundedContext Feature', ->
  eventStoreMock = null
  beforeEach ->
    eventStoreMock =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null

  describe 'given we created and initialized some example bounded context', ->
    exampleContext = null
    beforeEach ->
      exampleContext = eventric.boundedContext 'exampleContext'
      exampleContext.set 'store', eventStoreMock
      exampleContext.addAggregate 'Example', class Example


    describe 'when we command the bounded context to create an aggregate', ->
      beforeEach ->
        exampleContext.addCommand 'createExample', ->
          @$aggregate.create
            name: 'Example'


      it 'then it should haved triggered the correct DomainEvent', (done) ->
        exampleContext.addDomainEventHandler 'ExampleCreated', (domainEvent) ->
          expect(domainEvent.name).to.equal 'ExampleCreated'
          done()

        exampleContext.initialize()
        exampleContext.command
          name: 'createExample'


    describe 'when we command the bounded context to command an aggregate', ->
      beforeEach ->
        eventStoreMock.find.yields null, [
          name: 'ExampleCreated'
          aggregate:
            id: 1
            name: 'Example'
        ]

        class SomethingHappened
          constructor: (params) ->
            @someId   = params.someId
            @rootProp = params.rootProp
            @entity   = params.entity

        exampleContext.addDomainEvent 'SomethingHappened', SomethingHappened

        class ExampleEntity
          someEntityFunction: ->
            @entityProp = 'bar'

        class ExampleRoot
          doSomething: (someId) ->
            entity = new ExampleEntity
            entity.someEntityFunction()

            @$raiseDomainEvent 'SomethingHappened',
              someId: someId
              rootProp: 'foo'
              entity: entity

          handleExampleCreated: ->
            @entities = []

          handleSomethingHappened: (domainEvent) ->
            @someId = domainEvent.payload.someId
            @rootProp = domainEvent.payload.rootProp
            @entities[2] = domainEvent.payload.entity


        exampleContext.addAggregate 'Example', ExampleRoot

        exampleContext.addCommands
          someBoundedContextFunction: (params, callback) ->
            @$aggregate.command
              id: params.id
              name: 'Example'
              methodName: 'doSomething'
              methodParams: [1]
            .then =>
              callback null


      it 'then it should have triggered the correct DomainEvent', (done) ->
        exampleContext.addDomainEventHandler 'SomethingHappened', (domainEvent) ->
          expect(domainEvent.payload.entity.entityProp).to.equal 'bar'
          expect(domainEvent.name).to.equal 'SomethingHappened'
          done()

        exampleContext.initialize()
        exampleContext.command
          name: 'someBoundedContextFunction'
          params:
            id: 1


    describe 'when we use a command which calls a previously added adapter function', ->
      ExampleAdapter = null
      beforeEach ->
        class ExampleAdapter
          someAdapterFunction: sandbox.stub()
        exampleContext.addAdapter 'exampleAdapter', ExampleAdapter

        exampleContext.addApplicationService
          commands:
            doSomething: (params, callback) ->
              @$adapter('exampleAdapter').someAdapterFunction()
              callback()


      it 'then it should have called the adapter function', (done) ->
        exampleContext.initialize()
        exampleContext.command
          name: 'doSomething'
        , ->
          expect(ExampleAdapter::someAdapterFunction).to.have.been.calledOnce
          done()
