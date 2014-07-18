describe 'Create Aggregate Feature', ->
  eventStoreMock = null
  beforeEach ->
    eventStoreMock =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null

  describe 'given we created and initialized some example bounded microContext including an aggregate', ->
    exampleMicroContext = null
    beforeEach ->
      exampleMicroContext = eventric.microContext 'ExampleMicroContext'
      exampleMicroContext.set 'store', eventStoreMock
      exampleMicroContext.addDomainEvent 'ExampleCreated', (params) ->

      exampleMicroContext.addAggregate 'Example', class Example


    describe 'when we command the bounded microContext to create an aggregate without a create function', ->
      beforeEach ->
        exampleMicroContext.addCommandHandler 'CreateExample', (params, done) ->
          @$repository('Example').create()
          .then (exampleId) =>
            @$repository('Example').save exampleId
          .then =>
            done()


      it 'then it should haved triggered the correct DomainEvent', (done) ->
        exampleMicroContext.addDomainEventHandler 'ExampleCreated', (domainEvent) ->
          expect(domainEvent.name).to.equal 'ExampleCreated'
          done()

        exampleMicroContext.initialize =>
          exampleMicroContext.command
            name: 'CreateExample'
