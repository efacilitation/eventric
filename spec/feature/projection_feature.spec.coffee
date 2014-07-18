eventric = require 'eventric'

describe 'Projection Feature', ->

  projectionStoreStub = null
  storeStub = null
  beforeEach ->
    projectionStoreStub =
      insert: sandbox.stub()
      remove: sandbox.stub().yields null
    storeStub =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null
      collection: sandbox.stub().yields null, projectionStoreStub

  describe 'given we created and initialized some example bounded microContext including a Projection', ->
    exampleMicroContext = null
    beforeEach (done) ->
      storeStub.find.yields null, [
        name: 'ExampleCreated'
        aggregate:
          id: 1
          name: 'Example'
      ]

      exampleMicroContext = eventric.microContext 'exampleMicroContext'
      exampleMicroContext.set 'store', storeStub

      exampleMicroContext.addDomainEvents
        ExampleCreated: ->

        SomethingHappened: (params) ->
          @specific = params.whateverFoo

      class ExampleProjection
        handleSomethingHappened: (domainEvent) ->
          @$store.insert totallyDenormalized: domainEvent.payload.specific
      exampleMicroContext.addProjection 'ExampleProjection', ExampleProjection

      class ExampleAggregateRoot
        handleExampleCreated: (domainEvent) ->
          @whatever = 'bar'
        doSomething: ->
          if @whatever is 'bar'
            @$emitDomainEvent 'SomethingHappened', whateverFoo: 'foo'
        handleSomethingHappened: (domainEvent) ->
          @whatever = domainEvent.payload.whateverFoo
      exampleMicroContext.addAggregate 'Example', ExampleAggregateRoot

      exampleMicroContext.addCommandHandler 'doSomethingWithExample', (params, callback) ->
        @$repository('Example').findById params.id
        .then (example) =>
          example.doSomething()
          @$repository('Example').save params.id
        .then =>
          callback()

      exampleMicroContext.initialize =>
        done()


    describe 'when DomainEvents got emitted which the Projection subscribed to', ->
      it 'then the Projection should call $store with the denormalized state', (done) ->
        exampleMicroContext.command
          name: 'doSomethingWithExample'
          params:
            id: 1
        .then ->
          expect(projectionStoreStub.insert).to.have.been.calledWith totallyDenormalized: 'foo'
          done()
