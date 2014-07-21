eventric = require 'eventric'

describe 'Command Aggregate Feature', ->

  describe 'given we created and initialized some example context including an aggregate', ->
    exampleContext = null
    beforeEach ->
      exampleContext = eventric.context 'exampleContext'
      exampleContext.addAggregate 'Example', class Example


    describe 'when we send a command to the context', ->
      beforeEach ->
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
          someContextFunction: (params, callback) ->
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
          store = exampleContext.getStore()
          sandbox.stub store, 'find'
          store.find.yields null, [
            name: 'ExampleCreated'
            aggregate:
              id: 1
              name: 'Example'
          ]

          exampleContext.command
            name: 'someContextFunction'
            params:
              id: 1
