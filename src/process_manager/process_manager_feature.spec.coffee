describe 'ProcessManager', ->

  describe 'given we created a context and added a ProcessManager', ->
    initializeProcessManagerStub = null
    handleDomainEventProcessManagerStub = null
    exampleContext = null
    beforeEach ->
      initializeProcessManagerStub = sandbox.stub()
      handleDomainEventProcessManagerStub = sandbox.stub()
      eventric.addProcessManager 'ExampleProcess',
        initializeWhen:
          Example: [
            'ExampleCreated'
          ]
        class: ->
          initialize: (domainEvent) ->
            initializeProcessManagerStub()
            exampleContext.command 'ChangeExample',
              id: domainEvent.aggregate.id

          fromExample_handleExampleChanged: ->
            handleDomainEventProcessManagerStub()
            @$endProcess()

      exampleContext = eventric.context 'Example'

      exampleContext.defineDomainEvents
        ExampleCreated: ->
        ExampleChanged: ->

      class ExampleAggregateRoot
        create: (callback) ->
          @$emitDomainEvent 'ExampleCreated'
          callback()

        doSomething: ->
          @$emitDomainEvent 'ExampleChanged'

      exampleContext.addAggregate 'Example', ExampleAggregateRoot

      exampleContext.addCommandHandler 'CreateExample', (params, callback) ->
        @$aggregate.create 'Example'
        .then (example) =>
          example.$save()
        .then =>
          callback()

      exampleContext.addCommandHandler 'ChangeExample', (params, callback) ->
        @$aggregate.load 'Example', params.id
        .then (example) =>
          example.doSomething()
          example.$save()
        .then (exampleId) ->
          callback null, exampleId

      exampleContext.initialize()


    describe 'when a DomainEvent gets emitted the ProcessManager defined as initializeWhen', ->

      it 'then it should execute and end the process', (done) ->
        exampleContext.subscribeToDomainEvent 'ExampleChanged', (domainEvent) ->
          expect(initializeProcessManagerStub).to.have.been.called
          expect(handleDomainEventProcessManagerStub).to.have.been.called
          done()

        exampleContext.command 'CreateExample'
