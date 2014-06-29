describe 'Global Domain Event Handler Feature', ->
  storeStub = null
  beforeEach ->
    storeStub =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null

  describe 'given we created and initialized some example bounded context and added a global domain event handler', ->
    exampleContext = null
    specificHandlerStub = null
    allHandlerStub = null
    beforeEach ->
      # TODO: currently global domain event handlers have to be registered before calling eventric.boundedContext
      specificHandlerStub = sandbox.stub()
      eventric.addDomainEventHandler 'exampleContext', 'ExampleCreated', specificHandlerStub
      allHandlerStub = sandbox.stub()
      eventric.addDomainEventHandler 'exampleContext', 'all', allHandlerStub

      exampleContext = eventric.boundedContext 'exampleContext'
      exampleContext.set 'store', storeStub

      exampleContext.addAggregate 'Example', ->

      exampleContext.addCommandHandler 'createExample', (params, callback) ->
        @$aggregate.create
          name: 'Example'
        .then =>
          callback null


    describe 'when DomainEvents got emitted which the handler subscribed to', ->

      it 'then it should execute the registered global domain event handler', (done) ->
        exampleContext.initialize()
        exampleContext.command
          name: 'createExample'
        .then =>
          expect(specificHandlerStub).to.have.been.called
          expect(allHandlerStub).to.have.been.called
          done()
