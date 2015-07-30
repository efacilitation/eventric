describe 'Projection Feature', ->

  describe 'given an example context with one aggregate with two simple commands', ->
    exampleContext = null
    beforeEach ->
      exampleContext = eventric.context 'exampleContext'

      exampleContext.defineDomainEvents
        ExampleCreated: (params) ->
          @specific = params.specific


        ExampleModified: (params) ->
          @specific = params.specific


      exampleContext.addAggregate 'Example', ->
        create: ->
          @$emitDomainEvent 'ExampleCreated',
            specific: 'created'
        modify: ->
          @$emitDomainEvent 'ExampleModified',
            specific: 'modified'


      exampleContext.addCommandHandlers
        CreateExample: (params) ->
          exampleId = null
          @$aggregate.create 'Example'
          .then (example) ->
            example.$save()

        ModifyExample: (params) ->
          @$aggregate.load 'Example', params.id
          .then (example) ->
            example.modify()
            example.$save()


    describe 'when initializing the projection', ->

      it 'should set the projection to initialized', (done) ->
        exampleContext.addProjection 'ExampleProjection', ->
          stores: ['inmemory']

          handleExampleCreated: (domainEvent) ->
            expect(@isInitialized).to.equal true
            done()


        exampleContext.initialize()
        .then ->
          exampleContext.command 'CreateExample'


    describe 'when emitting domain events the projection subscribed to', ->

      it 'should execute the projection\'s event handlers and save it to the specified store', ->
        exampleContext.addProjection 'ExampleProjection', ->
          stores: ['inmemory']

          handleExampleCreated: (domainEvent) ->
            @$store.inmemory.exampleCreated = domainEvent.payload.specific


          handleExampleModified: (domainEvent) ->
            @$store.inmemory.exampleModified = domainEvent.payload.specific


        exampleContext.initialize()
        .then ->
          exampleContext.command 'CreateExample'
        .then (exampleId) ->
          exampleContext.command 'ModifyExample', id: exampleId
        .then ->
          exampleContext.getProjectionStore 'inmemory', 'ExampleProjection'
          .then (projectionStore) ->
            expect(projectionStore.exampleCreated).to.equal 'created'
            expect(projectionStore.exampleModified).to.equal 'modified'




      it 'should log an error given a domain event handler functions throws an error after initialization', ->
        exampleContext.addProjection 'ExampleProjection', ->
          stores: ['inmemory']

          handleExampleCreated: (domainEvent) ->
            throw new Error 'runtime error'

        new Promise (resolve, reject) ->
          exampleContext.initialize()
          .then ->
            exampleContext.command 'CreateExample'
          .then ->
            log = require '../logger'
            sandbox.stub log, 'error'
            setTimeout ->
              expect(log.error).to.have.been.calledOnce
              resolve()
          .catch reject
