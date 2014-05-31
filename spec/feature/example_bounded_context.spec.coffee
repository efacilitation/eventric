eventric = require 'eventric'

AggregateRoot = eventric.require 'AggregateRoot'

describe 'Example BoundedContext Feature', ->

  eventStoreMock =
    find: sandbox.stub().yields null, []
    save: sandbox.stub().yields null

  describe 'given we created some example bounded context', ->
    exampleContext = null

    beforeEach (done) ->
      class Example extends AggregateRoot

      exampleContext = eventric.boundedContext()
      exampleContext.set 'store', eventStoreMock
      exampleContext.initialize ->
        exampleContext.addAggregate 'Example', Example
        exampleContext.addCommand 'createExample', ->
          @domain.createAggregate 'Example', ->

        done()


    describe 'when we command the bounded context to create an aggregate', ->
      it 'then it should haved triggered an Aggregate:create DomainEvent', (done) ->
        exampleContext.onDomainEvent 'Example:create', (domainEvent) ->
          expect(domainEvent.getName()).to.equal 'create'
          done()

        exampleContext.command
          name: 'createExample'
