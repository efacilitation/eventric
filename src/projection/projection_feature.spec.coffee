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

      exampleContext.enableWaitingMode()
        
      exampleContext
      
    addProjection = ->
      exampleContext1.addProjection 'ExampleProjection', ->
        stores: ['inmemory']

        fromContext1_handleSomethingHappened: (domainEvent) ->
          @$store.inmemory.totallyDenormalizedc1 = domainEvent.payload.specific
          
        fromContext2_handleSomethingHappened: (domainEvent) ->
          @$store.inmemory.totallyDenormalizedc2 = domainEvent.payload.specific
          
      exampleContext1.initializeProjectionInstance 'ExampleProjection'
      
    beforeEach ->
      #eventric.log.setLogLevel('debug');
      exampleContext1 = createBasicContext 'Context1'
      exampleContext2 = createBasicContext 'Context2'
      
      Promise.all([
        exampleContext1.initialize()
        exampleContext2.initialize()
      ])
      
    
    
    describe 'when DomainEvents got emitted which the Projection subscribed to', ->
      it 'then the Projection should call the projectionStore with the denormalized state', ->
        addProjection()
        .then ->
          exampleContext2.command 'CreateExample'
        .then (exampleId) ->
          exampleContext2.command 'doSomethingWithExample', id: exampleId
        .then ->
          exampleContext1.getProjectionStore 'inmemory', 'ExampleProjection'
          .then (projectionStore) ->
            expect(projectionStore).to.deep.equal totallyDenormalizedc2: 'foo'
            
    describe 'when DomainEvents exists in stores before projection initialize', ->
      it 'then the projectionStore should be with the denormalized state', ->
        
        exampleContext2.command 'CreateExample'
        .then (exampleId) ->
          exampleContext2.command 'doSomethingWithExample', id: exampleId
        .then ->
          addProjection()
        .then ->
          exampleContext1.getProjectionStore 'inmemory', 'ExampleProjection'
          .then (projectionStore) ->
            expect(projectionStore).to.deep.equal totallyDenormalizedc2: 'foo'