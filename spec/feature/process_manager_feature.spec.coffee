eventric = require 'eventric'

describe.only 'ProcessManager', ->

  projectionStoreStub = null
  storeStub = null
  beforeEach ->
    projectionStoreStub =
      insert: sandbox.stub()
      remove: sandbox.stub().yields null
    storeStub =
      find: sandbox.stub().yields null, []
      save: sandbox.stub().yields null
      collection: sandbox.stub().yields null, projectionStoreStub

  describe 'given we created a microContext and added a ProcessManager', ->
    initializeProcessManagerStub = null
    handleDomainEventProcessManagerStub = null
    exampleMicroContext = null
    beforeEach ->
      storeStub.find.yields null, [
        name: 'ExampleCreated'
        aggregate:
          id: 1
          name: 'Example'
      ]

      initializeProcessManagerStub = sandbox.stub()
      handleDomainEventProcessManagerStub = sandbox.stub()
      eventric.addProcessManager 'ExampleProcess',
        initializeWhen:
          ExampleContext: 'ExampleCreated'
        class: ->
          initialize: ->
            initializeProcessManagerStub()
            exampleMicroContext.command
              name: 'DoSomethingWithExample'
              params:
                id: 1
            , ->

          handleExampleContextSomethingHappened: ->
            handleDomainEventProcessManagerStub()
            @$endProcess()

      exampleMicroContext = eventric.microContext 'ExampleContext'
      exampleMicroContext.set 'store', storeStub

      exampleMicroContext.addDomainEvents
        ExampleCreated: ->
        SomethingHappened: ->

      class ExampleAggregateRoot
        doSomething: ->
          @$emitDomainEvent 'SomethingHappened'

      exampleMicroContext.addAggregate 'Example', ExampleAggregateRoot

      exampleMicroContext.addCommandHandler 'CreateExample', (params, callback) ->
        @$repository('Example').create()
        .then (exampleId) =>
          @$repository('Example').save exampleId
        .then =>
          callback()

      exampleMicroContext.addCommandHandler 'DoSomethingWithExample', (params, callback) ->
        @$repository('Example').findById params.id
        .then (example) =>
          example.doSomething()
          @$repository('Example').save params.id
        .then =>
          callback()


    describe 'when a DomainEvent gets emitted the ProcessManager defined as initializeWhen', ->

      it 'then it should execute and end the process', (done) ->
        exampleMicroContext.addDomainEventHandler 'SomethingHappened', (domainEvent) ->
          expect(initializeProcessManagerStub).to.have.been.called
          expect(handleDomainEventProcessManagerStub).to.have.been.called
          done()

        exampleMicroContext.initialize =>
          exampleMicroContext.command
            name: 'CreateExample'
          .then ->