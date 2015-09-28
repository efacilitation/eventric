describe 'aggregate repository', ->
  domainEventSpecHelper = require 'eventric/domain_event/domain_event.spec_helper'
  aggregateRepository = null
  domainEventStoreFake = null
  firstDomainEvent = null
  secondDomainEvent = null
  firstDomainEventHandler = null
  secondDomainEventHandler = null
  contextFake = null

  firstDomainEventHandler = sandbox.stub()
  secondDomainEventHandler = sandbox.stub()

  class SampleAggregate
    handleFirstDomainEvent: firstDomainEventHandler
    handleSecondDomainEvent: secondDomainEventHandler

  class SampleAggregateWithCreateMethod
    create: sandbox.stub()
    handleFirstDomainEvent: firstDomainEventHandler
    handleSecondDomainEvent: secondDomainEventHandler

  AggregateRepository = require './'


  beforeEach ->
    domainEventStoreFake =
      findDomainEventsByAggregateId: sandbox.stub()
      saveDomainEvent: sandbox.stub()

    contextFake =
      getDomainEventsStore: ->
        return domainEventStoreFake
      getEventBus: ->
        return {
          publishDomainEvent: sandbox.stub()
        }

    firstDomainEvent = domainEventSpecHelper.createDomainEvent 'FirstDomainEvent'
    secondDomainEvent = domainEventSpecHelper.createDomainEvent 'SecondDomainEvent'


  describe '#load', ->

    beforeEach ->
      aggregateRepository = new AggregateRepository
        aggregateName: 'SampleAggregate'
        AggregateClass: SampleAggregate
        context: contextFake

    it 'should reject with an error given there is an error finding domain events', ->
      domainEventStoreFake.findDomainEventsByAggregateId
      .withArgs('aggregate-1')
      .yields new Error 'dummy error'

      aggregateRepository.load 'aggregate-1'
      .catch (error) ->
        expect(error.message).to.equal 'dummy error'


    it 'should reject with an error given there are no domain events', ->
      domainEventStoreFake.findDomainEventsByAggregateId
      .withArgs('aggregate-1')
      .yields null, null

      aggregateRepository.load 'aggregate-1'
      .catch (error) ->
        expect(error).to.be.instanceof Error


    describe 'given the domain event store delivers domain events', ->

      loadPromise = null

      beforeEach ->
        sandbox.stub aggregateRepository, 'save'

        domainEventStoreFake.findDomainEventsByAggregateId
        .withArgs('aggregate-1')
        .yields null, [secondDomainEvent, firstDomainEvent]

        loadPromise = aggregateRepository.load 'aggregate-1'


      it 'should return the domain events from the store ordered by the domain event id', ->
        expect(firstDomainEventHandler).to.have.been.calledBefore secondDomainEventHandler


      it 'should resolve with the aggregate instance', ->
        loadPromise.then (aggregateInstance) ->
          expect(aggregateInstance.$emitDomainEvent).to.be.a.function
          expect(aggregateInstance.$id).to.be.a.string


      it 'should call the $save() method of the aggregate repository \
      given $save() was called on the aggregate instance', ->
        loadPromise.then (aggregateInstance) ->
          aggregateInstance.$save()
          expect(aggregateRepository.save).to.have.been.calledOnce


  describe '#create', ->

    beforeEach ->
      aggregateRepository = new AggregateRepository
        aggregateName: 'SampleAggregate'
        AggregateClass: SampleAggregate
        context: contextFake

      sandbox.stub aggregateRepository, 'save'


    it 'should reject given there is no create method on the aggregate instance', ->
      aggregateRepository.create {}
      .catch (error) ->
        expect(error).to.be.instanceof Error


    describe 'given the aggregate instance has a create method', ->

      beforeEach ->
        aggregateRepository = new AggregateRepository
          aggregateName: 'SampleAggregateWithCreateMethod'
          AggregateClass: SampleAggregateWithCreateMethod
          context: contextFake

        sandbox.stub aggregateRepository, 'save'


      it 'should resolve with the aggregate instance', ->
        aggregateRepository.create {}
        .then (aggregateInstance) ->
          expect(aggregateInstance.$emitDomainEvent).to.be.a.function
          expect(aggregateInstance.$id).to.be.a.string


      it 'should call the aggregate instance create method', ->
        params = foo: 1
        aggregateRepository.create params
        .then (aggregateInstance) ->
          expect(aggregateInstance.create).to.have.been.calledWith params


      it 'should call the $save() method of the aggregate repository \
      given $save() was called on the aggregate instance', ->
        aggregateRepository.create {}
        .then (aggregateInstance) ->
          aggregateInstance.$save()
          expect(aggregateRepository.save).to.have.been.calledOnce


  describe '#save', ->

    beforeEach ->
      aggregateRepository = new AggregateRepository
        aggregateName: 'SampleAggregateWithCreateMethod'
        AggregateClass: SampleAggregateWithCreateMethod
        context: contextFake


    it 'should reject if no aggregate is given', ->
      aggregateRepository.save {}
      .catch (error) ->
        expect(error).to.be.instanceof Error


    it 'should reject given the aggregate has no domain events', ->
      aggregateRepository.save {getDomainEvents: -> return null}
      .catch (error) ->
        expect(error).to.be.instanceof Error


    it 'should reject given the event bus rejects with an error while publishing a domain event', ->
      aggregateRepository._context.getEventBus = ->
        return {
          publishDomainEvent: -> Promise.reject new Error 'dummy error'
        }
      aggregateRepository.save {getDomainEvents: -> return [1]}
      .catch (error) ->
        expect(error).to.be.instanceof Error


    describe 'given there are domain events for the aggregate', ->

      savePromise = null
      publishDomainEventStub = null

      beforeEach ->
        publishDomainEventStub = sandbox.stub().returns Promise.resolve()

        aggregateRepository._context.getEventBus = ->
          publishDomainEvent: publishDomainEventStub

        savePromise = aggregateRepository.save
          id: 'aggregate-id'
          getDomainEvents: ->
            return [
              firstDomainEvent, secondDomainEvent
            ]


      it 'should call saveDomainEvent on the store for each domain event', ->
        savePromise.then ->
          expect(domainEventStoreFake.saveDomainEvent).to.have.been.calledTwice


      it 'should call publishDomainEvent on the event bus for each domain event', ->
        savePromise.then ->
          expect(publishDomainEventStub).to.have.been.calledTwice


      it 'should resolve with the aggregate id', ->
        savePromise.then (aggregateId) ->
          expect(aggregateId).to.equal 'aggregate-id'
