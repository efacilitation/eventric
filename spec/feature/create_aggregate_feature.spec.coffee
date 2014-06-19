describe 'Create Aggregate Feature', ->
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


    describe 'when we command the bounded context to create an aggregate', ->
      beforeEach ->
        exampleContext.addCommandHandler 'createExample', ->
          @$aggregate.create
            name: 'Example'


      it 'then it should haved triggered the correct DomainEvent', (done) ->
        exampleContext.addDomainEventHandler 'ExampleCreated', (domainEvent) ->
          expect(domainEvent.name).to.equal 'ExampleCreated'
          done()

        exampleContext.initialize()
        exampleContext.command
          name: 'createExample'