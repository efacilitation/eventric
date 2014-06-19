eventric = require 'eventric'

describe 'Command Aggregate Feature', ->

  eventStoreMock = null
  beforeEach ->
    eventStoreMock =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null

  describe 'given we created and initialized some example bounded context including a view', ->
    exampleContext = null
    beforeEach ->
      exampleContext = eventric.boundedContext 'exampleContext'
      exampleContext.set 'store', eventStoreMock
      class SomethingHappened
        constructor: (params) ->
          @someProperty = params.someProperty

      exampleContext.addDomainEvent 'SomethingHappened', SomethingHappened

      class ExampleView
        subscribeToDomainEvents: [
          'SomethingHappened'
        ]

        handleSomethingHappened: (domainEvent) ->
          @totallyDenormalized = domainEvent.payload.someProperty


      exampleContext.addView 'ExampleView', ExampleView


    describe 'when DomainEvents got raised which the View subscribed to', ->
      beforeEach ->
        eventStoreMock.find.yields [
          name: 'SomethingHappened'
          payload:
            someProperty: 'foo'
        ]

      it.only 'then the View should be in the correct state when getting it', ->
        exampleView = exampleContext.getView 'ExampleView'
        expect(exampleView.totallyDenormalized).to.equal 'foo'