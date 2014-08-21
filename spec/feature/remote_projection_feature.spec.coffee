describe 'Remote Projection Feature', ->
  exampleContext  = null

  beforeEach (done) ->
    exampleContext = eventric.context 'Example'
    exampleContext.enableWaitingMode()
    exampleContext.defineDomainEvents
      ExampleCreated: ->
      ExampleUpdated: ->

    exampleContext.addCommandHandlers
      CreateExample: (params, callback) ->
        @$repository('Example').create()
        .then (exampleId) =>
          @$repository('Example').save exampleId
        .then (exampleId) ->
          callback null, exampleId
      UpdateExample: (params, callback) ->
        @$repository('Example').findById params.id
        .then (example) =>
          example.update()
          @$repository('Example').save params.id
        .then ->
          callback()

    class Example
      create: (callback) ->
        @$emitDomainEvent 'ExampleCreated'
        callback()
      update: ->
        @$emitDomainEvent 'ExampleUpdated'
    exampleContext.addAggregate 'Example', Example

    exampleContext.initialize ->
      done()


  describe 'given we created and initialized some example context', ->

    describe 'when we add a remote projection to the remote', ->
      projectionId = null
      exampleRemote = null

      beforeEach (done) ->
        exampleRemote = eventric.remote 'Example'

        class ExampleProjection

          initialize: (params) ->

          handleExampleCreated: (domainEvent) ->
            @created = true

        exampleRemote.addProjection 'ExampleProjection', ExampleProjection

        exampleRemote.initializeProjectionInstance 'ExampleProjection'
        .then (_projectionId) ->
          projectionId = _projectionId
          done()


      it 'then the projection should update the projection as expected', (done) ->
        exampleRemote.command 'CreateExample'
        .then ->
          exampleProjection = exampleRemote.getProjectionInstance projectionId
          expect(exampleProjection.created).to.be.true
          done()


      it 'then we should be able to remove it', ->
        sandbox.spy exampleRemote, 'unsubscribeFromDomainEvent'

        exampleProjection = exampleRemote.getProjectionInstance projectionId
        exampleRemote.destroyProjectionInstance projectionId

        expect(exampleRemote.getProjectionInstance projectionId).to.be.undefined
        expect(exampleRemote.unsubscribeFromDomainEvent).to.have.been.called


    describe 'when we add a remote projection, which subscribes to a specific aggregate, to the remote', ->
      exampleRemote = null
      projectionId  = null

      beforeEach ->
        exampleRemote = eventric.remote 'Example'

        class ExampleProjection

          initialize: (params) ->
            @$subscribeHandlersWithAggregateId params.aggregateId

          handleExampleUpdated: (domainEvent) ->
            @updated = true

        exampleRemote.addProjection 'ExampleProjection', ExampleProjection


      it 'then it should update the projection as expected', (done) ->
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
          done()


      it 'then we should be able to remove it', (done) ->
        exampleRemote.initializeProjectionInstance 'ExampleProjection', aggregateId: '123'
        .then (projectionId) ->
          sandbox.spy exampleRemote, 'unsubscribeFromDomainEventWithAggregateId'

          exampleProjection = exampleRemote.getProjectionInstance projectionId
          exampleRemote.destroyProjectionInstance projectionId

          expect(exampleRemote.getProjectionInstance projectionId).to.be.undefined
          expect(exampleRemote.unsubscribeFromDomainEventWithAggregateId).to.have.been.called
          done()
