describe 'aggregate repository', ->

  InmemoryRemote = require 'eventric-store-inmemory'
  EventBus = require 'eventric/event_bus'
  Aggregate = require 'eventric/aggregate'
  domainEventService = require 'eventric/domain_event/domain_event_service'

  domainEventSpecHelper = require 'eventric/domain_event/domain_event.spec_helper'

  aggregateRepository = null
  domainEventStoreStub = null
  eventBusStub = null

  contextStub = null

  AggregateRepository = require './'

  beforeEach ->
    domainEventStoreStub = sandbox.stub new InmemoryRemote
    eventBusStub = sandbox.stub new EventBus
    contextStub = sandbox.stub eventric.context 'fake'
    contextStub.getDomainEventsStore.returns domainEventStoreStub
    contextStub.getEventBus.returns eventBusStub


  describe '#load', ->

    beforeEach ->
      aggregateRepository = new AggregateRepository
        aggregateName: 'SampleAggregate'
        AggregateClass: class SampleAggregate
        context: contextStub


    it 'should ask the domain event store for domain events of the aggregate with given id', ->
      domainEvent = domainEventSpecHelper.createDomainEvent 'DomainEvent'
      domainEventStoreStub.findDomainEventsByAggregateId.yields null, [domainEvent]
      aggregateRepository.load 'aggregate-1'
      .then ->
        expect(domainEventStoreStub.findDomainEventsByAggregateId).to.have.been.calledWith 'aggregate-1'


    it 'should reject with an error given there is an error in finding domain events', ->
      domainEventStoreStub.findDomainEventsByAggregateId
      .yields new Error 'dummy error'

      aggregateRepository.load 'aggregate-1'
      .catch (error) ->
        expect(error.message).to.equal 'dummy error'


    it 'should reject with an error given there are no domain events', ->
      domainEventStoreStub.findDomainEventsByAggregateId
      .yields null, null

      aggregateRepository.load 'aggregate-1'
      .catch (error) ->
        expect(error).to.be.instanceof Error


    describe 'given the domain event store yields valid domain events', ->

      aggregateInstance = null

      firstDomainEvent = null
      secondDomainEvent = null
      domainEvents = null

      class SampleAggregate

      beforeEach ->
        sandbox.spy domainEventService, 'sortDomainEventsById'
        firstDomainEvent = domainEventSpecHelper.createDomainEvent 'FirstDomainEvent'
        secondDomainEvent = domainEventSpecHelper.createDomainEvent 'SecondDomainEvent'

        aggregateRepository = new AggregateRepository
          aggregateName: 'SampleAggregate'
          AggregateClass: SampleAggregate
          context: contextStub
        sandbox.stub aggregateRepository, 'save'

        domainEvents = [secondDomainEvent, firstDomainEvent]
        domainEventStoreStub.findDomainEventsByAggregateId
        .yields null, domainEvents

        sandbox.spy Aggregate::, 'applyDomainEvents'

        aggregateRepository.load 'aggregate-1'
        .then (_aggregateInstance_) ->
          aggregateInstance = _aggregateInstance_


      it 'should ask the domain event service to order the domain events by id', ->
        expect(domainEventService.sortDomainEventsById).to.have.been.calledWith domainEvents


      it 'should ask to apply the domain events in the correct order to the aggregate', ->
        expect(Aggregate::applyDomainEvents).to.have.been.calledWith [firstDomainEvent, secondDomainEvent]


      it 'should resolve with an aggregate instance', ->
        expect(aggregateInstance).to.be.an.instanceOf SampleAggregate
        expect(aggregateInstance.$emitDomainEvent).to.be.a.function
        expect(aggregateInstance.$id).to.be.a.string


      it 'should install a $save function on the aggregate instance which calls save on the aggregate repository', ->
        aggregateInstance.$save()
        expect(aggregateRepository.save).to.have.been.called
        expect(aggregateRepository.save.getCall(0).args[0]).to.be.an.instanceOf Aggregate


    describe 'given the domain event store yields events using the aggregate name followed by the word "Deleted" as name', ->

      beforeEach ->
        aggregateRepository = new AggregateRepository
          aggregateName: 'SampleAggregate'
          AggregateClass: class SampleAggregate
          context: contextStub


      it 'should reject with an error expressing that the aggregate has been marked as deleted', ->
        deletedDomainEvent = domainEventSpecHelper.createDomainEvent 'SampleAggregateDeleted'
        domainEventStoreStub.findDomainEventsByAggregateId.yields null, [deletedDomainEvent]
        aggregateRepository.load 'aggregate-1'
        .catch (error) ->
          expect(error.message).to.contain 'aggregate-1'
          expect(error.message).to.contain 'SampleAggregate'
          expect(error.message).to.contain 'SampleAggregateDeleted'


      it 'should always use the deleted event with the latest domain event id given there are multiple matching events', ->
        firstDomainEvent = domainEventSpecHelper.createDomainEvent 'SampleAggregateDeleted'
        secondDomainEvent = domainEventSpecHelper.createDomainEvent 'SampleAggregateDeleted'
        domainEventStoreStub.findDomainEventsByAggregateId.yields null, [secondDomainEvent, firstDomainEvent]
        aggregateRepository.load 'aggregate-1'
        .catch (error) ->
          expect(error.message).to.contain 'aggregate-1'
          expect(error.message).to.contain 'SampleAggregate'
          expect(error.message).to.contain 'SampleAggregateDeleted'
          expect(error.message).to.contain secondDomainEvent.id


    it 'should not reject given a domain event uses the word "Deleted" in its name but not combined with the aggregate name', ->
      domainEvent = domainEventSpecHelper.createDomainEvent 'SomeEntityDeleted'
      domainEventStoreStub.findDomainEventsByAggregateId.yields null, [domainEvent]
      loadingPromise = aggregateRepository.load 'aggregate-1'
      loadingPromise
      .then ->
        expect(loadingPromise).to.be.ok



  describe '#create', ->

    it 'should reject given there is no create method on the aggregate instance', ->
      aggregateRepository = new AggregateRepository
        aggregateName: 'SampleAggregate'
        AggregateClass: class SampleAggregate
        context: contextStub

      sandbox.stub aggregateRepository, 'save'
      aggregateRepository.create {}
      .catch (error) ->
        expect(error).to.be.instanceof Error


    describe 'given the aggregate instance has a create method', ->

      class SampleAggregate
        create: ->


      beforeEach ->
        aggregateRepository = new AggregateRepository
          aggregateName: 'SampleAggregate'
          AggregateClass: SampleAggregate
          context: contextStub

        sandbox.stub aggregateRepository, 'save'


      it 'should resolve with an aggregate instance', ->
        aggregateRepository.create {}
        .then (aggregateInstance) ->
          expect(aggregateInstance.$emitDomainEvent).to.be.a.function
          expect(aggregateInstance.$id).to.be.a.string
          expect(aggregateInstance).to.be.an.instanceOf SampleAggregate


      it 'should call the aggregate instance create method', ->
        params = foo: 1
        sandbox.spy SampleAggregate::, 'create'
        aggregateRepository.create params
        .then ->
          expect(SampleAggregate::create).to.have.been.calledWith params


      it 'should install a $save function on the aggregate instance which calls save on the aggregate repository', ->
        aggregateRepository.create {}
        .then (aggregateInstance) ->
          aggregateInstance.$save()
          expect(aggregateRepository.save).to.have.been.called
          expect(aggregateRepository.save.getCall(0).args[0]).to.be.an.instanceOf Aggregate
      
      it 'should set the aggregate id to a generated uuid, if no id is specified', ->
        aggregateRepository.create {}
        .then (aggregateInstance) ->
          expect(aggregateInstance.$id).to.be.a.string

      it 'should set the aggregate id to the specified id', ->
        id = 'someId'
        aggregateRepository.create {}, id
        .then (aggregateInstance) ->
          expect(aggregateInstance.$id).to.equal id


  describe '#save', ->

    class SampleAggregate
      create: ->

    beforeEach ->
      aggregateRepository = new AggregateRepository
        aggregateName: 'SampleAggregate'
        AggregateClass: SampleAggregate
        context: contextStub
      eventBusStub.publishDomainEvent.returns Promise.resolve()


    it 'should reject if no aggregate is given', ->
      aggregateRepository.save null
      .catch (error) ->
        expect(error).to.be.instanceof Error


    it 'should reject given the aggregate has no domain events', ->
      aggregate = new Aggregate contextStub, 'SampleAggregate', SampleAggregate
      aggregateRepository.save aggregate
      .catch (error) ->
        expect(error).to.be.instanceof Error
        expect(error.message).to.contain 'No new domain events'
        expect(error.message).to.contain 'SampleAggregate'
        expect(error.message).to.contain aggregate.id


    it 'should reject given the event bus rejects with an error while publishing a domain event', ->
      aggregateRepository._context.getEventBus = ->
        return {
          publishDomainEvent: -> Promise.reject new Error 'dummy error'
        }
      aggregateRepository.save {getDomainEvents: -> return [1]}
      .catch (error) ->
        expect(error).to.be.instanceof Error


    describe 'given there are new domain events for the aggregate', ->

      firstDomainEvent = null
      firstDomainEventSaved = null
      secondDomainEvent = null
      secondDomainEventSaved = null
      aggregate = null

      beforeEach ->
        firstDomainEvent = domainEventSpecHelper.createDomainEvent 'FirstDomainEvent'
        firstDomainEventSaved = domainEventSpecHelper.createDomainEvent 'FirstDomainEvent'

        secondDomainEvent = domainEventSpecHelper.createDomainEvent 'SecondDomainEvent'
        secondDomainEventSaved = domainEventSpecHelper.createDomainEvent 'SecondDomainEvent'

        aggregate = new Aggregate contextStub, 'SampleAggregate', SampleAggregate
        sandbox.stub(aggregate, 'getNewDomainEvents').returns [firstDomainEvent, secondDomainEvent]

        domainEventStoreStub.saveDomainEvent
        .withArgs firstDomainEvent
        .returns Promise.resolve firstDomainEventSaved

        domainEventStoreStub.saveDomainEvent
        .withArgs secondDomainEvent
        .returns Promise.resolve secondDomainEventSaved


      it 'should call saveDomainEvent on the store for each domain event', ->
        aggregateRepository.save aggregate
        .then ->
          expect(domainEventStoreStub.saveDomainEvent).to.have.been.calledTwice
          expect(domainEventStoreStub.saveDomainEvent.getCall(0).args[0]).to.equal firstDomainEvent
          expect(domainEventStoreStub.saveDomainEvent.getCall(1).args[0]).to.equal secondDomainEvent


      it 'should call publishDomainEvent on the event bus for each saved domain event', ->
        aggregateRepository.save aggregate
        .then ->
          expect(eventBusStub.publishDomainEvent).to.have.been.calledTwice
          expect(eventBusStub.publishDomainEvent.getCall(0).args[0]).to.equal firstDomainEventSaved
          expect(eventBusStub.publishDomainEvent.getCall(1).args[0]).to.equal secondDomainEventSaved


      it 'should resolve with the aggregate id', ->
        aggregateRepository.save aggregate
        .then (aggregateId) ->
          expect(aggregateId).to.equal aggregate.id
