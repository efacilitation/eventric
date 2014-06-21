eventric = require 'eventric'

describe 'Read Module Feature', ->

  eventStoreMock = null
  beforeEach ->
    eventStoreMock =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null

  describe 'given we created and initialized some example bounded context including a read model', ->
    exampleContext = null
    beforeEach ->
      exampleContext = eventric.boundedContext 'exampleContext'
      exampleContext.set 'store', eventStoreMock
      class SomethingHappened
        constructor: (params) ->
          @someProperty = params.someProperty

      exampleContext.addDomainEvent 'SomethingHappened', SomethingHappened

      class ExampleReadModel
        subscribeToDomainEvents: [
          'SomethingHappened'
        ]

        handleSomethingHappened: (domainEvent) ->
          @totallyDenormalized = domainEvent.payload.someProperty

      exampleContext.addAggregate 'Example', class Example
      exampleContext.addReadModel 'ExampleReadModel', ExampleReadModel

      exampleContext.initialize()


    describe 'when DomainEvents got raised which the ReadModel subscribed to', ->
      beforeEach ->
        eventStoreMock.find.yields [
          name: 'SomethingHappened'
          payload:
            someProperty: 'foo'
        ]

      it 'then the ReadModel should be in the correct state when getting it', ->
        exampleReadModel = exampleContext.getReadModel 'ExampleReadModel'
        expect(exampleReadModel.totallyDenormalized).to.equal 'foo'