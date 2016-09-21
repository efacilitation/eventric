describe 'Global Projection Feature', ->

  firstContext = null
  secondContext = null

  contextSpecHelper = null

  beforeEach ->
    contextSpecHelper = require 'eventric/context/context.spec_helper'

    firstContext = contextSpecHelper.createContextWithOneAggregate
      contextName: 'First'
      aggregateName: 'FirstContextAggregate'

    secondContext = contextSpecHelper.createContextWithOneAggregate
      contextName: 'Second'
      aggregateName: 'SecondContextAggregate'

    Promise.all [
      firstContext.initialize()
      secondContext.initialize()
    ]


  describe 'given a global projection which handles events from multiple contexts', ->

    receivedDomainEventNames = null

    beforeEach ->
      receivedDomainEventNames = []
      globalProjection =
        initialize: (params, done) ->
          done()

        handleFirstContextAggregateCreated: (domainEvent) ->
          receivedDomainEventNames.push domainEvent.name


        handleFirstContextAggregateModified: (domainEvent) ->
          receivedDomainEventNames.push domainEvent.name


        handleSecondContextAggregateCreated: (domainEvent) ->
          receivedDomainEventNames.push domainEvent.name


      eventric.addGlobalProjection globalProjection


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


      it 'should replay events with identical timestamps from one context in the same order they are received', ->
        currentTimestamp = Date.now()
        sandbox.stub(Date::, 'getTime').returns currentTimestamp
        firstContext.command 'CreateAggregate'
        .then (aggregateId) ->
          firstContext.command 'ModifyAggregate', aggregateId: aggregateId
        .then ->
          eventric.initializeGlobalProjections()
        .then ->
          expect(receivedDomainEventNames).to.deep.equal ['FirstContextAggregateCreated', 'FirstContextAggregateModified']


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
