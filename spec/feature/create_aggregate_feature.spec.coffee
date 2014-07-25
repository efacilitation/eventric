describe 'Create Aggregate Feature', ->
  describe 'given we created and initialized some example context including an aggregate', ->
    exampleContext = null
    beforeEach ->
      exampleContext = eventric.context 'Examplecontext'
      exampleContext.addDomainEvent 'ExampleCreated', (params) ->

      exampleContext.addAggregate 'Example', ->


    describe 'when we command the context to create an aggregate without a create function', ->
      beforeEach ->
        exampleContext.addCommandHandler 'CreateExample', (params, done) ->
          @$repository('Example').create()
          .then (exampleId) =>
            @$repository('Example').save exampleId
          .then =>
            done()


      it 'then it should haved triggered the correct DomainEvent', (done) ->
        exampleContext.addDomainEventHandler 'ExampleCreated', (domainEvent) ->
          expect(domainEvent.name).to.equal 'ExampleCreated'
          done()

        exampleContext.initialize =>
          exampleContext.command 'CreateExample'
