eventric = require 'eventric'

describe 'Command Aggregate Feature', ->

  eventStoreMock = null
  beforeEach ->
    eventStoreMock =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null

  describe 'given we created and initialized some example bounded context including an aggregate', ->
    exampleContext = null
    beforeEach ->
      exampleContext = eventric.boundedContext 'exampleContext'
      exampleContext.set 'store', eventStoreMock
      exampleContext.addAggregate 'Example', class Example


    describe 'when we send a command to the bounded context', ->
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

            @$emitDomainEvent 'SomethingHappened',
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

        exampleContext.addCommandHandlers
          someBoundedContextFunction: (params, callback) ->
            @$repository('Example').findById params.id
            .then (example) =>
              example.doSomething [1]
              @$repository('Example').save params.id
            .then ->
              callback()


      it 'then it should have triggered the correct DomainEvent', (done) ->
        exampleContext.addDomainEventHandler 'SomethingHappened', (domainEvent) ->
          expect(domainEvent.payload.entity.entityProp).to.equal 'bar'
          expect(domainEvent.name).to.equal 'SomethingHappened'
          done()

        exampleContext.initialize =>
          exampleContext.command
            name: 'someBoundedContextFunction'
            params:
              id: 1
