eventric = require 'eventric'

describe 'Example BoundedContext Feature', ->
  eventStoreMock = null
  beforeEach ->
    eventStoreMock =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null

  describe 'given we created some example bounded context', ->
    exampleContext = null
    beforeEach (done) ->
      exampleContext = eventric.boundedContext()
      exampleContext.set 'store', eventStoreMock
      exampleContext.addAggregate 'Example', {}
      exampleContext.addCommand 'createExample', ->
        @aggregate.create 'Example', ->

      exampleContext.initialize ->
        done()


    describe 'when we command the bounded context to create an aggregate', ->
      it 'then it should haved triggered an Aggregate:create DomainEvent', (done) ->
        exampleContext.onDomainEvent 'Example:create', (domainEvent) ->
          expect(domainEvent.getName()).to.equal 'create'
          done()

        exampleContext.command
          name: 'createExample'
