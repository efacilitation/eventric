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

      exampleProjection = null

      beforeEach ->
        exampleRemote = eventric.remoteContext 'Example'

        exampleProjection =

          initialize: (params, done) ->
            done()

          handleExampleCreated: (domainEvent) ->
            @created = true

          handleToCheckCorrectFunctionCall: (domainEvent) ->

        exampleRemote.initializeProjection exampleProjection
        .then (_projectionId_) ->
          projectionId = _projectionId_


      it 'should update the projection state as expected', ->
        exampleRemote.command 'CreateExample'
        .then ->
          expect(exampleProjection.created).to.be.true


      it 'should be possible to remove the projection', ->
        sandbox.spy exampleRemote, 'unsubscribeFromDomainEvent'

        exampleRemote.destroyProjectionInstance projectionId

        expect(exampleRemote.unsubscribeFromDomainEvent).to.have.been.called


    describe 'initializing a projection as object on the remote', ->

      exampleProjection = null

      beforeEach ->
        exampleRemote = eventric.remoteContext 'Example'
        exampleProjection =
          initialize: (params, done) ->
            done()

          handleExampleCreated: (domainEvent) ->
            @created = true

          handleToCheckCorrectFunctionCall: (domainEvent) ->

        exampleRemote.initializeProjection exampleProjection
        .then (_projectionId_) ->
          projectionId = _projectionId_


      it 'should update the projection state as expected', ->
        exampleRemote.command 'CreateExample'
        .then ->
          expect(exampleProjection.created).to.be.true


    describe 'adding a remote projection to the remote which subscribes to a specific aggregate', ->
      projectionId  = null
      exampleProjection = null

      beforeEach ->
        exampleRemote = eventric.remoteContext 'Example'

        exampleProjection =

          initialize: (params, done) ->
            @$subscribeHandlersWithAggregateId params.aggregateId
            done()


          handleExampleUpdated: (domainEvent) ->
            @updated = true


      it 'should update the projection state as expected', ->
        testExampleId = null
        exampleRemote.command 'CreateExample'
        .then (exampleId) ->
          testExampleId = exampleId
          exampleRemote.initializeProjection exampleProjection, aggregateId: testExampleId
          exampleRemote.command 'CreateExample'
        .then (exampleId) ->
          exampleRemote.command 'UpdateExample',
            id: exampleId
        .then ->
          expect(exampleProjection.updated).not.to.be.true
          exampleRemote.command 'UpdateExample',
            id: testExampleId
          new Promise (resolve) ->
            setTimeout resolve
        .then ->
          expect(exampleProjection.updated).to.be.true


      it 'should be possible to remove the projection', ->
        exampleRemote.initializeProjection exampleProjection, aggregateId: 'aggregate-1'
        .then (projectionId) ->
          sandbox.spy exampleRemote, 'unsubscribeFromDomainEvent'

          exampleRemote.destroyProjectionInstance projectionId
          expect(exampleRemote.unsubscribeFromDomainEvent).to.have.been.called


    describe 'adding a remote projection for which matching domain events already exist', ->

      it 'should apply the already existing domain events immediately to the projection', ->
        exampleRemote = eventric.remoteContext 'Example'

        exampleProjection =

          exampleCount: 0

          handleExampleCreated: ->
            @exampleCount++


        exampleContext.command 'CreateExample'
        .then ->
          exampleRemote.initializeProjection exampleProjection
        .then ->
          expect(exampleProjection.exampleCount).to.equal 1


    describe 'adding a remote projection for a specific aggregate id for which matching domain events already exist', ->

      exampleProjection = null

      beforeEach ->
        exampleRemote = eventric.remoteContext 'Example'

        exampleProjection =

          updated: false

          initialize: (params, done) ->
            @$subscribeHandlersWithAggregateId params.aggregateId
            done()

          handleExampleCreated: ->
            @created = true

          handleExampleUpdated: ->
            @updated = true


      it 'should apply the already existing domain events immediately to the projection', ->
        exampleContext.command 'CreateExample'
        .then (id) ->
          exampleContext.command 'UpdateExample', id: id
          .then ->
            exampleRemote.initializeProjection exampleProjection, aggregateId: id
        .then ->
          expect(exampleProjection.updated).to.be.true


      it 'should only apply the already existing domain events for the specific aggregate', ->
        firstExampleId = null
        exampleContext.command 'CreateExample'
        .then (_firstExampleId_) ->
          firstExampleId = _firstExampleId_
          exampleContext.command 'CreateExample'
        .then (secondExampleId) ->
          exampleContext.command 'UpdateExample', id: secondExampleId
        .then ->
          exampleRemote.initializeProjection exampleProjection, aggregateId: firstExampleId
        .then ->
          expect(exampleProjection.updated).to.be.false


      it '[bugfix] should call all handle functions given there are events already stored', ->
        projection = null
        exampleContext.command 'CreateExample'
        .then (id) ->
          exampleContext.command 'UpdateExample', id: id
          .then ->
            exampleRemote.initializeProjection exampleProjection, aggregateId: id
        .then ->
          expect(exampleProjection.updated).to.be.true


    describe 'adding a remote projection for which multiple matching domain events already exist', ->

      exampleProjection = null

      beforeEach ->
        exampleRemote = eventric.remoteContext 'Example'

        exampleProjection =

          events: []

          handleExampleCreated: (domainEvent) ->
            @events.push domainEvent.name

          handleExampleUpdated: (domainEvent) ->
            @events.push domainEvent.name


      it 'should apply the already existing domain events in the correct order', ->
        exampleContext.command 'CreateExample'
        .then (id) ->
          exampleContext.command 'UpdateExample', id: id
        .then ->
          exampleRemote.initializeProjection exampleProjection
        .then ->
          expect(exampleProjection.events).to.deep.equal ['ExampleCreated', 'ExampleUpdated']


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

      firstProjection = null
      secondProjection = null

      beforeEach ->
        exampleRemote = eventric.remoteContext 'Example'

        firstProjection =

          initialize: (params, done) ->
            @actions = []
            done()


          handleExampleCreated: (domainEvent) ->
            @actions.push 'created'


        exampleRemote.initializeProjection firstProjection


        secondProjection =

          initialize: (params, done) ->
            @actions = []
            done()

          handleExampleCreated: (domainEvent) ->
            @actions.push 'created'


          handleExampleModified: (domainEvent) ->
            @actions.push 'modified'


        exampleRemote.initializeProjection secondProjection


      describe 'when emitting domain events the projections subscribed to', ->

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
