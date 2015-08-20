describe 'aggregate repository', ->
  domainEventSpecHelper = require 'eventric/domain_event/domain_event.spec_helper'
  aggregateRepository = null
  domainEventStoreFake = null
  firstDomainEvent = null
  secondDomainEvent = null
  firstDomainEventHandler = null
  secondDomainEventHandler = null

  beforeEach ->
    domainEventStoreFake =
      findDomainEventsByAggregateId: sandbox.stub()

    contextFake =
      getDomainEventsStore: ->
        return domainEventStoreFake

    firstDomainEvent = domainEventSpecHelper.createDomainEvent 'FirstDomainEvent'
    secondDomainEvent = domainEventSpecHelper.createDomainEvent 'SecondDomainEvent'

    firstDomainEventHandler = sandbox.stub()
    secondDomainEventHandler = sandbox.stub()

    class SampleAggregate
      handleFirstDomainEvent: firstDomainEventHandler
      handleSecondDomainEvent: secondDomainEventHandler

    AggregateRepository = require './'
    aggregateRepository = new AggregateRepository
      aggregateName: 'SampleAggregate'
      AggregateClass: SampleAggregate
      context: contextFake


  describe '#load', ->

    it 'should return the domain events from the store ordered by the domain event id', ->
      domainEventStoreFake.findDomainEventsByAggregateId.withArgs('aggregate-1')
        .yields null, [secondDomainEvent, firstDomainEvent]
      aggregateRepository.load 'aggregate-1'
      .then ->
        expect(firstDomainEventHandler).to.have.been.calledBefore secondDomainEventHandler
