eventric = require 'eventric'

describe 'Example BoundedContext Feature', ->
  eventStoreMock = null
  beforeEach ->
    eventStoreMock =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null

  describe 'given we created some example bounded context', ->
    exampleContext = null
    beforeEach ->
      exampleContext = eventric.boundedContext()
      exampleContext.set 'store', eventStoreMock
      exampleContext.addAggregate 'Example', {}


    describe 'when we command the bounded context to create an aggregate', ->
      beforeEach (done) ->
        exampleContext.addCommand 'createExample', ->
          @aggregate.create 'Example', ->

        exampleContext.initialize ->
          done()


      it 'then it should haved triggered an Aggregate:create DomainEvent', (done) ->
        exampleContext.onDomainEvent 'Example:create', (domainEvent) ->
          expect(domainEvent.getName()).to.equal 'create'
          done()

        exampleContext.command
          name: 'createExample'


    describe 'when we query the bounded context', ->
      beforeEach (done) ->
        eventStoreMock.find.yields null, [
          aggregate:
            id: 1
            name: 'Example'
            changed:
              props:
                foo: 'bar'
        ]

        exampleContext.addQuery 'getExample', (params, callback) ->
          @repository('Example').findById 1, (err, readExample) ->
            callback null, readExample

        exampleContext.initialize ->
          done()


      it 'then it should return the correct read aggregate', (done) ->
        exampleContext.query
          name: 'getExample'
          , (err, readExample) ->
            expect(readExample.foo).to.equal 'bar'
            done()
