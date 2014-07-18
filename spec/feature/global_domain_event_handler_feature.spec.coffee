describe 'Global Domain Event Handler Feature', ->
  storeStub = null
  beforeEach ->
    storeStub =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null

  describe 'given we created and initialized some example bounded microContext and added a global domain event handler', ->
    exampleMicroContext = null
    specificOnMicroContextHandlerStub = null
    allOnMicroContextHandlerStub = null
    allHandlerStub = null
    beforeEach ->
      # TODO: currently global domain event handlers have to be registered before calling eventric.microContext
      specificOnMicroContextHandlerStub = sandbox.stub()
      eventric.addDomainEventHandler 'exampleMicroContext', 'ExampleCreated', specificOnMicroContextHandlerStub
      allOnMicroContextHandlerStub = sandbox.stub()
      eventric.addDomainEventHandler 'exampleMicroContext', allOnMicroContextHandlerStub
      allHandlerStub = sandbox.stub()
      eventric.addDomainEventHandler allHandlerStub

      exampleMicroContext = eventric.microContext 'exampleMicroContext'
      exampleMicroContext.set 'store', storeStub

      exampleMicroContext.addDomainEvent 'ExampleCreated', ->

      exampleMicroContext.addAggregate 'Example', ->

      exampleMicroContext.addCommandHandler 'createExample', (params, done) ->
        @$repository('Example').create()
        .then (exampleId) =>
          @$repository('Example').save exampleId
        .then =>
          done null


    describe 'when DomainEvents got emitted which the handler subscribed to', ->

      it 'then it should execute the registered global domain event handler', (done) ->
        exampleMicroContext.initialize =>
          exampleMicroContext.command
            name: 'createExample'
          .then =>
            expect(specificOnMicroContextHandlerStub).to.have.been.called
            expect(allOnMicroContextHandlerStub).to.have.been.called
            expect(allHandlerStub).to.have.been.called
            done()
