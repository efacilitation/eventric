describe 'Remote Projection Feature', ->
  exampleContext  = null

  beforeEach ->
    exampleContext = eventric.context 'Example'
    exampleContext.defineDomainEvents
      ExampleCreated: ->
      ExampleUpdated: ->

    exampleContext.addCommandHandlers
      CreateExample: (params, callback) ->
        @$aggregate.create 'Example'
        .then (example) ->
          example.$save()
        .then (exampleId) ->
          callback null, exampleId
      UpdateExample: (params, callback) ->
        @$aggregate.load 'Example', params.id
        .then (example) ->
          example.update()
          example.$save()
        .then (exampleId) ->
          callback null, exampleId

    class Example
      create: (callback) ->
        @$emitDomainEvent 'ExampleCreated'
        callback()
      update: ->
        @$emitDomainEvent 'ExampleUpdated'

    exampleContext.addAggregate 'Example', Example

    exampleContext.initialize()
    .then ->
      exampleContext.enableWaitingMode()


  describe 'given we created and initialized some example context', ->

    describe 'when we add a projection to the remote', ->
      projectionId = null
      exampleRemote = null

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


      it 'then the projection should update its state as expected', ->
        exampleRemote.command 'CreateExample'
        .then ->
          exampleProjection = exampleRemote.getProjectionInstance projectionId
          expect(exampleProjection.created).to.be.true


      it 'then we should be able to remove it', ->
        sandbox.spy exampleRemote, 'unsubscribeFromDomainEvent'

        exampleRemote.destroyProjectionInstance projectionId

        expect(exampleRemote.getProjectionInstance projectionId).to.be.undefined
        expect(exampleRemote.unsubscribeFromDomainEvent).to.have.been.called


    describe 'when we initialize a projection as object on the remote', ->
      projectionId = null
      exampleRemote = null

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


      it 'then the projection should update its state as expected', ->
        exampleRemote.command 'CreateExample'
        .then ->
          exampleProjection = exampleRemote.getProjectionInstance projectionId
          expect(exampleProjection.created).to.be.true


    describe 'when we add a remote projection to the remote which subscribes to a specific aggregate', ->
      exampleRemote = null
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


      it 'then should update the remote projection as expected', ->
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


      it 'then should publish an event whenever a remote projection is updated', (done) ->
        testExampleId = null
        exampleRemote.command 'CreateExample'
        .then (exampleId) ->
          testExampleId = exampleId
          exampleRemote.initializeProjectionInstance 'ExampleProjection', aggregateId: exampleId
        .then (projectionId) ->
          exampleProjection = exampleRemote.getProjectionInstance projectionId
          exampleRemote.subscribe 'projection:ExampleProjection:changed', ->
            done()
          exampleRemote.command 'UpdateExample',
            id: testExampleId


      it 'then we should be able to remove it', ->
        exampleRemote.initializeProjectionInstance 'ExampleProjection', aggregateId: '123'
        .then (projectionId) ->
          sandbox.spy exampleRemote, 'unsubscribeFromDomainEvent'

          exampleRemote.destroyProjectionInstance projectionId

          expect(exampleRemote.getProjectionInstance projectionId).to.be.undefined
          expect(exampleRemote.unsubscribeFromDomainEvent).to.have.been.called


    describe 'when we add a remote projection and already have domain events for it', ->

      exampleRemote = null

      beforeEach ->
        exampleRemote = eventric.remote 'Example'

        class ExampleProjection

          constructor: ->
            @exampleCount = 0

          handleExampleCreated: ->
            @exampleCount++

        exampleRemote.addProjection 'ExampleProjection', ExampleProjection


      it 'then it should apply the already existing domain events immediately to the projection', ->
        exampleContext.command 'CreateExample'
        .then (id) ->
          exampleRemote.initializeProjectionInstance 'ExampleProjection'
        .then (projectionId) ->
          projection = exampleRemote.getProjectionInstance projectionId
          expect(projection.exampleCount).to.equal 1


    describe 'when we add a remote projection for a specific aggregate id and have domain events for it', ->

      exampleRemote = null

      beforeEach ->
        #eventric.log.setLogLevel 'debug'
        exampleRemote = eventric.remote 'Example'

        class ExampleProjection

          constructor: ->
            @updated = false

          initialize: (params, done) ->
            @$subscribeHandlersWithAggregateId params.aggregateId
            done()

          handleExampleUpdated: ->
            @updated = true

        exampleRemote.addProjection 'ExampleProjection', ExampleProjection


      it 'then it should apply the already existing domain events immediately to the projection', ->
        exampleContext.command 'CreateExample'
        .then (exampleId) ->
          exampleContext.command 'UpdateExample', id: exampleId
        .then (exampleId) ->
          exampleRemote.initializeProjectionInstance 'ExampleProjection', aggregateId: exampleId
        .then (projectionId) ->
          projection = exampleRemote.getProjectionInstance projectionId
          expect(projection.updated).to.be.true


      it 'then it should only apply the already existing domain events for the specific aggregate', ->
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


    describe 'when we add a remote projection and already have multiple domain events for it', ->

      exampleRemote = null

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


      it 'then it should apply the already existing domain events in the correct order', ->
        exampleContext.command 'CreateExample'
        .then (id) ->
          exampleContext.command 'UpdateExample', id: id
        .then (id) ->
          exampleRemote.initializeProjectionInstance 'ExampleProjection'
        .then (projectionId) ->
          projection = exampleRemote.getProjectionInstance projectionId
          expect(projection.events).to.deep.equal ['ExampleCreated', 'ExampleUpdated']
