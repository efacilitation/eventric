describe 'Global Projection Feature', ->

  firstContext = null
  secondContext = null

  beforeEach ->
    firstContext = createContextWithOneAggregate
      contextName: 'First'
      aggregateName: 'FirstContextAggregate'
      domainEventName: 'FirstContextAggregateCreated'

    secondContext = createContextWithOneAggregate
      contextName: 'Second'
      aggregateName: 'SecondContextAggregate'
      domainEventName: 'SecondContextAggregateCreated'

    Promise.all [
      firstContext.initialize()
      secondContext.initialize()
    ]


  describe 'given a global projection which handles events from multiple contexts', ->

    receivedDomainEventNames = null

    beforeEach ->
      receivedDomainEventNames = []
      class GlobalProjection
        initialize: (params, done) ->
          done()

        handleFirstContextAggregateCreated: (domainEvent) ->
          receivedDomainEventNames.push domainEvent.name

        handleSecondContextAggregateCreated: (domainEvent) ->
          receivedDomainEventNames.push domainEvent.name


      eventric.addGlobalProjection GlobalProjection


    describe 'initializing the projection', ->

      it 'should correctly replay those events given there are saved domain events from the first context', ->
        firstContext.command 'CreateAggregate'
        .then ->
          eventric.initializeGlobalProjections()
        .then ->
          expect(receivedDomainEventNames).to.deep.equal ['FirstContextAggregateCreated']


      it 'should correctly replay those events given there are saved domain events from the second context', ->
        secondContext.command 'CreateAggregate'
        .then ->
          eventric.initializeGlobalProjections()
        .then ->
          expect(receivedDomainEventNames).to.deep.equal ['SecondContextAggregateCreated']


      it 'should replay all events in correct order given there are saved domain events from all contexts', ->
        secondContext.command 'CreateAggregate'
        .then ->
          firstContext.command 'CreateAggregate'
        .then ->
          eventric.initializeGlobalProjections()
        .then ->
          expect(receivedDomainEventNames).to.deep.equal ['SecondContextAggregateCreated', 'FirstContextAggregateCreated']


    describe 'receiving domain events on the projection', ->

      it 'should correctly handle those events given new events are emitted on the first context', ->
        eventric.initializeGlobalProjections()
        .then ->
          firstContext.command 'CreateAggregate'
        .then ->
          expect(receivedDomainEventNames).to.deep.equal ['FirstContextAggregateCreated']


      it 'should correctly handle those events given new events are emitted on the second context', ->
        eventric.initializeGlobalProjections()
        .then ->
          secondContext.command 'CreateAggregate'
        .then ->
          expect(receivedDomainEventNames).to.deep.equal ['SecondContextAggregateCreated']


      it 'should correctly handle those events in order given new events are emitted on all contexts', ->
        eventric.initializeGlobalProjections()
        .then ->
          secondContext.command 'CreateAggregate'
        .then ->
          firstContext.command 'CreateAggregate'
        .then ->
          expect(receivedDomainEventNames).to.deep.equal ['SecondContextAggregateCreated', 'FirstContextAggregateCreated']


createContextWithOneAggregate = ({contextName, aggregateName, domainEventName}) ->

  context = eventric.context contextName

  context.defineDomainEvent domainEventName, ->
  context.addAggregate aggregateName, ->
    create: (params) ->
      @$emitDomainEvent domainEventName

  context.addCommandHandler 'CreateAggregate', ->
    @$aggregate.create aggregateName
    .then (aggregate) ->
      aggregate.$save()

  context