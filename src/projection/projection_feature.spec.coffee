describe 'Projection Feature', ->

  describe 'given we created and initialized some example context including a Projection', ->
    exampleContext = null
    beforeEach ->
      exampleContext = eventric.context 'exampleContext'

      exampleContext.defineDomainEvents
        ExampleCreated: ->

        SomethingHappened: (params) ->
          @specific = params.whateverFoo

      exampleContext.addProjection 'ExampleProjection', ->
        stores: ['inmemory']

        handleSomethingHappened: (domainEvent, promise) ->
          @$store.inmemory.totallyDenormalized = domainEvent.payload.specific
          promise.resolve()

      exampleContext.addAggregate 'Example', ->
        create: ->
          @$emitDomainEvent 'ExampleCreated'
        handleExampleCreated: (domainEvent) ->
          @whatever = 'bar'
        doSomething: ->
          if @whatever is 'bar'
            @$emitDomainEvent 'SomethingHappened', whateverFoo: 'foo'
        handleSomethingHappened: (domainEvent) ->
          @whatever = domainEvent.payload.whateverFoo

      exampleContext.addCommandHandlers
        CreateExample: (params) ->
          exampleId = null
          @$aggregate.create 'Example'
          .then (example) ->
            example.$save()

        doSomethingWithExample: (params) ->
          @$aggregate.load 'Example', params.id
          .then (example) ->
            example.doSomething()
            example.$save()

      exampleContext.initialize()
      .then ->
        exampleContext.enableWaitingMode()


    describe 'when DomainEvents got emitted which the Projection subscribed to', ->
      it 'then the Projection should call the projectionStore with the denormalized state', ->
        exampleContext.command 'CreateExample'
        .then (exampleId) ->
          exampleContext.command 'doSomethingWithExample', id: exampleId
        .then ->
          exampleContext.getProjectionStore 'inmemory', 'ExampleProjection'
          .then (projectionStore) ->
            expect(projectionStore).to.deep.equal totallyDenormalized: 'foo'
