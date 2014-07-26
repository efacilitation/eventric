describe 'Global Domain Event Handler Feature', ->

  describe 'given we created and initialized some example context and added a global domain event handler', ->
    exampleContext = null
    specificOncontextHandlerStub = null
    allOncontextHandlerStub = null
    allHandlerStub = null
    beforeEach ->
      # TODO: currently global domain event handlers have to be registered before calling eventric.context
      specificOncontextHandlerStub = sandbox.stub()
      eventric.addDomainEventHandler 'exampleContext', 'ExampleCreated', specificOncontextHandlerStub
      allOncontextHandlerStub = sandbox.stub()
      eventric.addDomainEventHandler 'exampleContext', allOncontextHandlerStub
      allHandlerStub = sandbox.stub()
      eventric.addDomainEventHandler allHandlerStub

      exampleContext = eventric.context 'exampleContext'

      exampleContext.addDomainEvent 'ExampleCreated', ->

      exampleContext.addAggregate 'Example', ->
        create: ->
          @$emitDomainEvent 'ExampleCreated'

      exampleContext.addCommandHandler 'createExample', (params, done) ->
        @$repository('Example').create()
        .then (exampleId) =>
          @$repository('Example').save exampleId
        .then =>
          done null


    describe 'when DomainEvents got emitted which the handler subscribed to', ->

      it 'then it should execute the registered global domain event handler', (done) ->
        exampleContext.initialize =>
          exampleContext.command 'createExample'
          .then =>
            expect(specificOncontextHandlerStub).to.have.been.called
            expect(allOncontextHandlerStub).to.have.been.called
            expect(allHandlerStub).to.have.been.called
            done()
