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

        handleSomethingHappened: (domainEvent, done) ->
          @$store.inmemory.totallyDenormalized = domainEvent.payload.specific
          done()

      exampleContext.addAggregate 'Example', ->
        create: (callback) ->
          @$emitDomainEvent 'ExampleCreated'
          callback()
        handleExampleCreated: (domainEvent) ->
          @whatever = 'bar'
        doSomething: ->
          if @whatever is 'bar'
            @$emitDomainEvent 'SomethingHappened', whateverFoo: 'foo'
        handleSomethingHappened: (domainEvent) ->
          @whatever = domainEvent.payload.whateverFoo

      exampleContext.addCommandHandlers
        CreateExample: (params, callback) ->
          exampleId = null
          @$repository('Example').create()
          .then (exampleId) =>
            @$repository('Example').save exampleId
          .then (exampleId) ->
            callback null, exampleId

        doSomethingWithExample: (params, callback) ->
          @$repository('Example').findById params.id
          .then (example) =>
            example.doSomething()
            @$repository('Example').save params.id
          .then ->
            callback()

      exampleContext.initialize()
      .then ->
        exampleContext.enableWaitingMode()


    describe 'when DomainEvents got emitted which the Projection subscribed to', ->
      it 'then the Projection should call the projectionStore with the denormalized state', ->
        exampleContext.command 'CreateExample'
        .then (exampleId) ->
          exampleContext.command 'doSomethingWithExample', id: exampleId
        .then ->
          exampleContext.getProjectionStore 'inmemory', 'ExampleProjection', (err, projectionStore) ->
            expect(projectionStore).to.deep.equal totallyDenormalized: 'foo'
