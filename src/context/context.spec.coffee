describe 'context', ->
  domainEventSpecHelper = require 'eventric/domain_event/domain_event.spec_helper'
  context = null
  firstDomainEvent = null
  secondDomainEvent = null

  beforeEach ->
    class StoreFake
      initialize: ->
        Promise.resolve()
      findDomainEventsByName: ->
      findDomainEventsByNameAndAggregateId: ->

    storeDefinitionFake =
      Class: StoreFake

    eventric = require '../eventric'
    sandbox.stub(eventric, 'getStoreDefinition').returns storeDefinitionFake

    firstDomainEvent = domainEventSpecHelper.createDomainEvent()
    secondDomainEvent = domainEventSpecHelper.createDomainEvent()

    Context = require './'
    context = new Context 'SampleContext'
    context.initialize()


  describe '#findDomainEventsByName', ->

    it 'should return the domain events from the store ordered by the domain event id', ->
      sandbox.stub(context.getDomainEventsStore(), 'findDomainEventsByName').yields null, [secondDomainEvent, firstDomainEvent]
      context.findDomainEventsByName()
      .then (domainEvents) ->
        expect(domainEvents).to.deep.equal [firstDomainEvent, secondDomainEvent]


  describe '#findDomainEventsByNameAndAggregateId', ->

    it 'should return the domain events from the store ordered by the domain event id', ->
      sandbox.stub(context.getDomainEventsStore(), 'findDomainEventsByNameAndAggregateId')
        .yields null, [secondDomainEvent, firstDomainEvent]
      context.findDomainEventsByNameAndAggregateId()
      .then (domainEvents) ->
        expect(domainEvents).to.deep.equal [firstDomainEvent, secondDomainEvent]
