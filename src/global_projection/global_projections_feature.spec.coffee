describe 'Global Projection Feature', ->

  describe 'given we created and initialized some example contexts then create a Global Projection', ->
    exampleContext1 = null
    exampleContext2 = null
    
    createBasicContext = (name) ->
      exampleContext = eventric.context name

      exampleContext.defineDomainEvents
        ExampleCreated: ->

        SomethingHappened: (params) ->
          @specific = params.whateverFoo

      exampleContext.addAggregate 'Example', ->
        create: ->
          @$emitDomainEvent 'ExampleCreated'
        doSomething: ->
          @$emitDomainEvent 'SomethingHappened', whateverFoo: 'foo'

      exampleContext.addCommandHandlers
        CreateExample: () ->
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
        
      exampleContext
      
    beforeEach ->
      exampleContext1 = createBasicContext 'Context1'
      exampleContext2 = createBasicContext 'Context2'
      
      eventric.addGlobalProjection 'ExampleProjection', ->
        stores: ['inmemory']

        fromContext1_handleSomethingHappened: (domainEvent, promise) ->
          console.log '1'
          @$store.inmemory.totallyDenormalizedc1 = domainEvent.payload.specific
          promise.resolve()
          
        fromContext2_handleSomethingHappened: (domainEvent, promise) ->
          console.log '2'
          @$store.inmemory.totallyDenormalizedc2 = domainEvent.payload.specific
          promise.resolve()
    
    
    describe 'when DomainEvents got emitted which the Projection subscribed to', ->
      it 'then the Projection should call the projectionStore with the denormalized state', ->
        exampleContext1.command 'CreateExample'
        .then (exampleId) ->
          exampleContext1.command 'doSomethingWithExample', id: exampleId
        .then ->
          eventric.getContext('GlobalProjectionsContext').getProjectionStore 'inmemory', 'ExampleProjection'
          .then (projectionStore) ->
            expect(projectionStore).to.deep.equal totallyDenormalizedc1: 'foo'
