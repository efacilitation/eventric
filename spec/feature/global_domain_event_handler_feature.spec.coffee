describe 'Global Domain Event Handler Feature', ->
  storeStub = null
  beforeEach ->
    storeStub =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null

  describe 'given we created and initialized some example bounded context and added a global domain event handler', ->
    exampleContext = null
    specificOnContextHandlerStub = null
    allOnContextHandlerStub = null
    allHandlerStub = null
    beforeEach ->
      # TODO: currently global domain event handlers have to be registered before calling eventric.boundedContext
      specificOnContextHandlerStub = sandbox.stub()
      eventric.addDomainEventHandler 'exampleContext', 'ExampleCreated', specificOnContextHandlerStub
      allOnContextHandlerStub = sandbox.stub()
      eventric.addDomainEventHandler 'exampleContext', allOnContextHandlerStub
      allHandlerStub = sandbox.stub()
      eventric.addDomainEventHandler allHandlerStub

      exampleContext = eventric.boundedContext 'exampleContext'
      exampleContext.set 'store', storeStub

      exampleContext.addDomainEvent 'ExampleCreated', ->

      exampleContext.addAggregate 'Example', ->

      exampleContext.addCommandHandler 'createExample', (params, done) ->
        @$repository('Example').create()
        .then (exampleId) =>
          @$repository('Example').save exampleId
        .then =>
          done null


    describe 'when DomainEvents got emitted which the handler subscribed to', ->

      it 'then it should execute the registered global domain event handler', (done) ->
        exampleContext.initialize =>
          exampleContext.command
            name: 'createExample'
          .then =>
            expect(specificOnContextHandlerStub).to.have.been.called
            expect(allOnContextHandlerStub).to.have.been.called
            expect(allHandlerStub).to.have.been.called
            done()