describe 'Global Projection Feature', ->

  describe 'given multiple contexts with distinctly named domain events', ->

    firstContext = null
    secondContext = null

    receivedDomainEventNames = null

    beforeEach ->
      receivedDomainEventNames = []

      firstContext = eventric.context 'First'

      firstContext.defineDomainEvent 'FirstContextAggregateCreated', ->
      firstContext.addAggregate 'FirstContextAggregate', ->
        create: (params) ->
          @$emitDomainEvent 'FirstContextAggregateCreated'

      firstContext.addCommandHandler 'CreateAggregate', ->
        @$aggregate.create 'FirstContextAggregate'
        .then (aggregate) ->
          aggregate.$save()


      secondContext = eventric.context 'Second'

      secondContext.defineDomainEvent 'SecondContextAggregateCreated', ->
      secondContext.addAggregate 'SecondContextAggregate', ->
        create: (params) ->
          @$emitDomainEvent 'SecondContextAggregateCreated'

      secondContext.addCommandHandler 'CreateAggregate', ->
        @$aggregate.create 'SecondContextAggregate'
        .then (aggregate) ->
          aggregate.$save()


      Promise.all [
        firstContext.initialize()
        secondContext.initialize()
      ]


    describe 'creating a projection which handles events from all contexts', ->

      projection = null

      beforeEach ->
        projection =
          initialize: (params, done) ->
            done()

          handleFirstContextAggregateCreated: (domainEvent) ->
            receivedDomainEventNames.push domainEvent.name

          handleSecondContextAggregateCreated: (domainEvent) ->
            receivedDomainEventNames.push domainEvent.name


      describe 'given there are already saved domain events on the first context', ->


        beforeEach ->
          firstContext.command 'CreateAggregate'
          .then ->
            eventric.initializeProjection projection


        it 'should correctly replay those events', ->
          expect(receivedDomainEventNames).to.deep.equal ['FirstContextAggregateCreated']



      describe 'given there are already saved domain events on the second context', ->

        beforeEach ->
          secondContext.command 'CreateAggregate'
          .then ->
            eventric.initializeProjection projection


        it 'should correctly replay those events', ->
          expect(receivedDomainEventNames).to.deep.equal ['SecondContextAggregateCreated']


      describe 'given there are already saved domain events for all contexts', ->

        beforeEach ->
          secondContext.command 'CreateAggregate'
          .then ->
            firstContext.command 'CreateAggregate'
          .then ->
            eventric.initializeProjection projection


        it 'should replay all events in correct order', ->
          expect(receivedDomainEventNames).to.deep.equal ['SecondContextAggregateCreated', 'FirstContextAggregateCreated']



      describe 'given new events are emitted on the first context', ->

        beforeEach (done) ->
          eventric.initializeProjection projection
          .then ->
            firstContext.subscribeToDomainEvent 'FirstContextAggregateCreated', ->
              done()
          .then ->
            firstContext.command 'CreateAggregate'


        it 'should correctly handle those events', ->
          expect(receivedDomainEventNames).to.deep.equal ['FirstContextAggregateCreated']


      describe 'given new events are emitted on the second context', ->

        beforeEach (done) ->
          eventric.initializeProjection projection
          .then ->
            secondContext.subscribeToDomainEvent 'SecondContextAggregateCreated', ->
              done()
          .then ->
            secondContext.command 'CreateAggregate'


        it 'should correctly handle those events', ->
          expect(receivedDomainEventNames).to.deep.equal ['SecondContextAggregateCreated']


      describe 'given new events are emitted on all contexts', ->

        beforeEach (done) ->
          eventric.initializeProjection projection
          .then ->
            firstContext.subscribeToDomainEvent 'FirstContextAggregateCreated', ->
              done()
          .then ->
            secondContext.command 'CreateAggregate'
          .then ->
            firstContext.command 'CreateAggregate'


        it 'should correctly handle those events', ->
          expect(receivedDomainEventNames).to.deep.equal ['SecondContextAggregateCreated', 'FirstContextAggregateCreated']