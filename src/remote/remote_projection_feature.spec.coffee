describe 'Remote Projection Feature', ->
  exampleContext  = null
  exampleRemote   = null
  projectionId    = null

  describe 'given a context with one aggregate with two commands', ->

    beforeEach ->
      exampleContext = eventric.context 'Example'
      exampleContext.defineDomainEvents
        ExampleCreated: ->
        ExampleUpdated: ->

      exampleContext.addCommandHandlers
        CreateExample: (params) ->
          @$aggregate.create 'Example'
          .then (example) ->
            example.$save()
        UpdateExample: (params) ->
          @$aggregate.load 'Example', params.id
          .then (example) ->
            example.update()
            example.$save()

      class Example
        create: ->
          @$emitDomainEvent 'ExampleCreated'
        update: ->
          @$emitDomainEvent 'ExampleUpdated'

      exampleContext.addAggregate 'Example', Example

      exampleContext.initialize()


    describe 'adding a projection to the remote', ->

      beforeEach ->
        exampleRemote = eventric.remote 'Example'

        class ExampleProjection

          initialize: (params, done) ->
            done()

          handleExampleCreated: (domainEvent) ->
            @created = true

          handleToCheckCorrectFunctionCall: (domainEvent) ->


        exampleRemote.addProjection 'ExampleProjection', ExampleProjection

        exampleRemote.initializeProjectionInstance 'ExampleProjection'
        .then (_projectionId) ->
          projectionId = _projectionId


      it 'should update the projection state as expected', ->
        exampleRemote.command 'CreateExample'
        .then ->
          exampleProjection = exampleRemote.getProjectionInstance projectionId
          expect(exampleProjection.created).to.be.true


      it 'should be possible to remove the projection', ->
        sandbox.spy exampleRemote, 'unsubscribeFromDomainEvent'

        exampleRemote.destroyProjectionInstance projectionId

        expect(exampleRemote.getProjectionInstance projectionId).to.be.undefined
        expect(exampleRemote.unsubscribeFromDomainEvent).to.have.been.called


    describe 'initializing a projection as object on the remote', ->

      beforeEach ->
        exampleRemote = eventric.remote 'Example'
        exampleRemote.initializeProjection
          initialize: (params, done) ->
            done()

          handleExampleCreated: (domainEvent) ->
            @created = true

          handleToCheckCorrectFunctionCall: (domainEvent) ->

        .then (_projectionId) ->
          projectionId = _projectionId


      it 'should update the projection state as expected', ->
        exampleRemote.command 'CreateExample'
        .then ->
          exampleProjection = exampleRemote.getProjectionInstance projectionId
          expect(exampleProjection.created).to.be.true


    describe 'adding a remote projection to the remote which subscribes to a specific aggregate', ->
      projectionId  = null

      beforeEach ->
        exampleRemote = eventric.remote 'Example'

        class ExampleProjection

          initialize: (params, done) ->
            @$subscribeHandlersWithAggregateId params.aggregateId
            done()

          handleExampleUpdated: (domainEvent) ->
            @updated = true

        exampleRemote.addProjection 'ExampleProjection', ExampleProjection


      it 'should update the projection state as expected', ->
        testExampleId = null
        exampleRemote.command 'CreateExample'
        .then (exampleId) ->
          testExampleId = exampleId
          exampleRemote.initializeProjectionInstance 'ExampleProjection', aggregateId: exampleId
        .then (_projectionId) ->
          projectionId = _projectionId
          exampleRemote.command 'CreateExample'
        .then (exampleId) ->
          exampleRemote.command 'UpdateExample',
            id: exampleId
        .then ->
          exampleProjection = exampleRemote.getProjectionInstance projectionId
          expect(exampleProjection.updated).not.to.be.true
          exampleRemote.command 'UpdateExample',
            id: testExampleId
        .then ->
          exampleProjection = exampleRemote.getProjectionInstance projectionId
          expect(exampleProjection.updated).to.be.true


      it 'should be possible to remove the projection', ->
        exampleRemote.initializeProjectionInstance 'ExampleProjection', aggregateId: '123'
        .then (projectionId) ->
          sandbox.spy exampleRemote, 'unsubscribeFromDomainEvent'

          exampleRemote.destroyProjectionInstance projectionId

          expect(exampleRemote.getProjectionInstance projectionId).to.be.undefined
          expect(exampleRemote.unsubscribeFromDomainEvent).to.have.been.called


    describe 'adding a remote projection for which matching domain events already exist', ->

      beforeEach ->
        exampleRemote = eventric.remote 'Example'

        class ExampleProjection

          constructor: ->
            @exampleCount = 0

          handleExampleCreated: ->
            @exampleCount++

        exampleRemote.addProjection 'ExampleProjection', ExampleProjection


      it 'should apply the already existing domain events immediately to the projection', ->
        exampleContext.command 'CreateExample'
        .then (id) ->
          exampleRemote.initializeProjectionInstance 'ExampleProjection'
        .then (projectionId) ->
          projection = exampleRemote.getProjectionInstance projectionId
          expect(projection.exampleCount).to.equal 1


    describe 'adding a remote projection for a specific aggregate id for which matching domain events already exist', ->

      beforeEach ->
        exampleRemote = eventric.remote 'Example'

        class ExampleProjection

          constructor: ->
            @updated = false

          initialize: (params, done) ->
            @$subscribeHandlersWithAggregateId params.aggregateId
            done()

          handleExampleCreated: ->
            @created = true

          handleExampleUpdated: ->
            @updated = true

        exampleRemote.addProjection 'ExampleProjection', ExampleProjection


      it 'should apply the already existing domain events immediately to the projection', ->
        exampleContext.command 'CreateExample'
        .then (exampleId) ->
          exampleContext.command 'UpdateExample', id: exampleId
        .then (exampleId) ->
          exampleRemote.initializeProjectionInstance 'ExampleProjection', aggregateId: exampleId
        .then (projectionId) ->
          projection = exampleRemote.getProjectionInstance projectionId
          expect(projection.updated).to.be.true


      it 'should only apply the already existing domain events for the specific aggregate', ->
        firstExampleId = null
        exampleContext.command 'CreateExample'
        .then (_firstExampleId) ->
          firstExampleId = _firstExampleId
          exampleContext.command 'CreateExample'
        .then (secondExampleId) ->
          exampleContext.command 'UpdateExample', id: secondExampleId
        .then ->
          exampleRemote.initializeProjectionInstance 'ExampleProjection', aggregateId: firstExampleId
        .then (projectionId) ->
          projection = exampleRemote.getProjectionInstance projectionId
          expect(projection.updated).to.be.false


      it '[bugfix] should call all handle functions given there are events already stored', ->
        exampleId = null
        projection = null
        exampleContext.command 'CreateExample'
        .then (_exampleId) ->
          exampleId = _exampleId
          exampleRemote.initializeProjectionInstance 'ExampleProjection', aggregateId: exampleId
        .then (projectionId) ->
          projection = exampleRemote.getProjectionInstance projectionId
          exampleContext.command 'UpdateExample', id: exampleId
        .then ->
          expect(projection.updated).to.be.true


    describe 'adding a remote projection  for which multiple matching domain events already exist', ->

      beforeEach ->
        exampleRemote = eventric.remote 'Example'

        class ExampleProjection

          constructor: ->
            @events = []

          handleExampleCreated: (domainEvent) ->
            @events.push domainEvent.name

          handleExampleUpdated: (domainEvent) ->
            @events.push domainEvent.name

        exampleRemote.addProjection 'ExampleProjection', ExampleProjection


      it 'should apply the already existing domain events in the correct order', ->
        exampleContext.command 'CreateExample'
        .then (id) ->
          exampleContext.command 'UpdateExample', id: id
        .then (id) ->
          exampleRemote.initializeProjectionInstance 'ExampleProjection'
        .then (projectionId) ->
          projection = exampleRemote.getProjectionInstance projectionId
          expect(projection.events).to.deep.equal ['ExampleCreated', 'ExampleUpdated']


  describe 'given a context with one aggregate which emits two domain events in one behavior', ->

    beforeEach ->
      exampleContext = eventric.context 'Example'

      exampleContext.defineDomainEvents
        ExampleCreated: ->
        ExampleModified: ->

      exampleContext.addAggregate 'Example', ->
        create: (params) ->
          @$emitDomainEvent 'ExampleCreated'
          @modify params

        modify: (params) ->
          @$emitDomainEvent 'ExampleModified'


      exampleContext.addCommandHandlers
        CreateExample: (params) ->
          exampleId = null
          @$aggregate.create 'Example',
            foo: 'bar'
          .then (example) ->
            example.$save()


        ModifyExample: (params) ->
          exampleId = null
          @$aggregate.load 'Example', params.exampleId
          .then (example) ->
            example.modify()
            example.$save()


      exampleContext.initialize()


    describe 'given two projections where the first one listen to one event and the second one to both events', ->

      beforeEach ->
        exampleRemote = eventric.remote 'Example'

        exampleRemote.addProjection 'FirstProjection', ->

          initialize: (params, done) ->
            @actions = []
            done()


          handleExampleCreated: (domainEvent) ->
            @actions.push 'created'


        exampleRemote.addProjection 'SecondProjection', ->

          initialize: (params, done) ->
            @actions = []
            done()

          handleExampleCreated: (domainEvent) ->
            @actions.push 'created'


          handleExampleModified: (domainEvent) ->
            @actions.push 'modified'


      describe 'when emitting domain events the projections subscribed to', ->

        secondProjection = null

        beforeEach ->
          exampleRemote.initializeProjectionInstance 'FirstProjection'
          .then (firstProjectionId) ->
            exampleRemote.initializeProjectionInstance 'SecondProjection'
          .then (secondProjectionId) ->
            secondProjection = exampleRemote.getProjectionInstance secondProjectionId


        it 'should execute the second projection\'s event handlers in the correct order', ->
          new Promise (resolve, reject) ->
            exampleRemote.subscribeToDomainEvent 'ExampleModified', ->
              try
                expect(secondProjection.actions[0]).to.equal 'created'
                expect(secondProjection.actions[1]).to.equal 'modified'
                resolve()
              catch reject

            exampleRemote.command 'CreateExample'
            .then (exampleId) ->
              exampleRemote.command 'ModifyExample',
                exampleId: exampleId
            .catch reject
