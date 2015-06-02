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


createContextWithOneAggregate = ({contextName, aggregateName, domainEventName}) ->

  context = eventric.context contextName

  context.defineDomainEvent domainEventName, ->
  context.addAggregate aggregateName, ->
    create: (params) ->
      @$emitDomainEvent domainEventName

  context.addCommandHandlers
    CreateAggregate: ->
      @$aggregate.create aggregateName
      .then (aggregate) ->
        aggregate.$save()

  context
