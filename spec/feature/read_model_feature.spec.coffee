eventric = require 'eventric'

describe 'Read Module Feature', ->

  readStoreStub = null
  storeStub = null
  beforeEach ->
    readStoreStub =
      insert: sandbox.stub()
    storeStub =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null
      collection: sandbox.stub().yields null, readStoreStub

  describe 'given we created and initialized some example bounded context including a read model', ->
    exampleContext = null
    beforeEach ->
      storeStub.find.yields null, [
        name: 'ExampleCreated'
        aggregate:
          id: 1
          name: 'Example'
      ]

      exampleContext = eventric.boundedContext 'exampleContext'
      exampleContext.set 'store', storeStub

      class SomethingHappened
        constructor: (params) ->
          @someProperty = params.someProperty
      exampleContext.addDomainEvent 'SomethingHappened', SomethingHappened

      class ExampleReadModel
        subscribeToDomainEvents: [
          'SomethingHappened'
        ]

        handleSomethingHappened: (domainEvent) ->
          @$store.insert totallyDenormalized: domainEvent.payload.someProperty
      exampleContext.addReadModel 'ExampleReadModel', ExampleReadModel

      class ExampleAggregateRoot
        doSomething: ->
          @$emitDomainEvent 'SomethingHappened', someProperty: 'foo'
        handleExampleCreated: ->
        handleSomethingHappened: ->
      exampleContext.addAggregate 'Example', ExampleAggregateRoot

      exampleContext.addCommandHandler 'doSomethingWithExample', (params, callback) ->
        @$aggregate.command
          id: params.id
          name: 'Example'
          methodName: 'doSomething'
        .then =>
          callback null

      exampleContext.initialize()


    describe 'when DomainEvents got emitted which the ReadModel subscribed to', ->
      it 'then the ReadModel should call $store with the denormalized state', (done) ->
        exampleContext.command
          name: 'doSomethingWithExample'
          params:
            id: 1
        .then ->
          expect(readStoreStub.insert).to.have.been.calledWith totallyDenormalized: 'foo'
          done()
