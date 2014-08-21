describe 'Remote Projection Feature', ->
  exampleContext  = null

  beforeEach (done) ->
    exampleContext = eventric.context 'Example'
    exampleContext.enableWaitingMode()
    exampleContext.defineDomainEvents
      ExampleCreated: ->

    exampleContext.addCommandHandlers
      CreateExample: (params, callback) ->
        @$repository('Example').create()
        .then (exampleId) =>
          @$repository('Example').save exampleId
        .then ->
          callback()

    class Example
      create: (callback) ->
        @$emitDomainEvent 'ExampleCreated'
        callback()
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
            @data = 'foo'

        exampleRemote.addProjection 'ExampleProjection', ExampleProjection

        exampleRemote.initializeProjectionInstance 'ExampleProjection', aggregateId: 123
        .then (_projectionId) ->
          projectionId = _projectionId
          done()


      it.only 'then the projection should work as expected', (done) ->
        exampleRemote.command 'CreateExample'
        .then ->
          exampleProjection = exampleRemote.getProjectionInstance projectionId
          expect(exampleProjection.data).to.equal 'foo'
          done()
